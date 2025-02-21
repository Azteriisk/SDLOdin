// How this thing works:
//  - Create SDL Context
//  - Create a Window
//  - Create a Renderer
//  - Create Clean-Up/Destruction Methods for the Window & Renderer
//  - Clear & Present Render to Renderer
//  - Poll predefined events looking for changes
//  - Switch through present event types to handle requests appropriately
//  - Initialize SDL2 Image Context
//  - Creates graphics layers with SDL RenderCopies starting with a background layer

package main

import "core:fmt"
import "core:os"
import sdl "vendor:sdl2"
import img "vendor:sdl2/image"
import str "core:strings"
import time "core:time" // Import the time package

SDL_FLAGS :: sdl.INIT_EVERYTHING
IMG_FLAGS :: img.INIT_PNG | img.INIT_JPG
WINDOW_FLAGS :: sdl.WINDOW_SHOWN
RENDER_FLAGS :: sdl.RENDERER_ACCELERATED

WINDOW_TITLE :: "SDL Application"
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 600
FRAMERATE_TARGET :: 90

App :: struct {
    window:     ^sdl.Window,
    renderer:   ^sdl.Renderer,
    event:      sdl.Event,
    background: ^sdl.Texture,
    player:     Player,
}

Player :: struct {
    textures:      [4]^sdl.Texture, // Array to hold sprite textures
    current_frame: int,            // Current frame index
    frame_time:    f32,            // Time per frame
    player_render: sdl.Rect,         // Player render rectangle
    last_frame_time: u32,          // Time of the last frame update
}

app_cleanup :: proc(a: ^App) {
    if a != nil {

        if a.background != nil {
            for i := 0; i < len(a.player.textures); i += 1 {
                if a.player.textures[i] != nil {
                    sdl.DestroyTexture(a.player.textures[i])
                }
            }
        }
        if a.background != nil {sdl.DestroyTexture(a.background)}

        if a.renderer != nil {sdl.DestroyRenderer(a.renderer)}
        if a.window != nil {sdl.DestroyWindow(a.window)}

        img.Quit()
        sdl.Quit()
    }
}

initialize :: proc(a: ^App) -> bool {
    if sdl.Init(SDL_FLAGS) != 0 {
        fmt.eprintfln("Error Initializing SDL2: %s", sdl.GetError())
        return false
    }

    img_init := img.Init(IMG_FLAGS)
    if (img_init & IMG_FLAGS) != IMG_FLAGS {
        fmt.eprintfln("Error Initializing SDL2 Image: %s", img.GetError())
        return false

    }

    a.window = sdl.CreateWindow(
        WINDOW_TITLE,
        sdl.WINDOWPOS_CENTERED,
        sdl.WINDOWPOS_CENTERED,
        SCREEN_WIDTH,
        SCREEN_HEIGHT,
        WINDOW_FLAGS,
    )

    if a.window == nil {
        fmt.eprintfln("Error Creating Window: %s", sdl.GetError())
        return false
    }

    a.renderer = sdl.CreateRenderer(a.window, -1, RENDER_FLAGS)

    // Load sprite textures
    for i in 0..=3 {
        frame_number := i + 1  // Store the integer value
        texture_path_str := fmt.tprintf("images/dude%d.png", frame_number) // Create Odin string
        texture_path_cstring := str.clone_to_cstring(texture_path_str) // Convert to cstring

        a.player.textures[i] = img.LoadTexture(a.renderer, texture_path_cstring)
        if a.player.textures[i] == nil {
            fmt.eprintfln("Error Loading Texture %s: %s", texture_path_str, img.GetError())
            return false
        }
        delete(texture_path_cstring) // Free the allocated cstring
    }

    a.player.current_frame = 0
    a.player.frame_time = 1000.0 / 4.0; // 4 FPS (Animation speed set to 4 FPS)
    a.player.player_render = sdl.Rect{
        200,
        450,
        100,
        100,
    }
    a.player.last_frame_time = sdl.GetTicks() // Initialize last frame time


    if a.renderer == nil {
        fmt.eprintfln("Error Creating Renderer: %s", sdl.GetError())
        return false
    }
    return true
}

load_media :: proc(a: ^App) -> bool {
    bg_path_str := "images/bg.jpg" // Odin string for background path
    bg_path_cstring := str.clone_to_cstring(bg_path_str) // Convert to cstring

    a.background = img.LoadTexture(a.renderer, bg_path_cstring)
    if a.background == nil {
        fmt.eprintfln("Error Loading Textures: %s", bg_path_str, img.GetError())
        return false
    }
    delete(bg_path_cstring) // Free allocated cstring for background


    return true

}

app_run :: proc(a: ^App) {
    for {
        // events
        for sdl.PollEvent(&a.event) {
            #partial switch a.event.type {
            case .QUIT:
                return
            case .KEYDOWN:
                #partial switch a.event.key.keysym.scancode {
                case .ESCAPE:
                    return
                }
            }
        }

        // state update
        current_time := sdl.GetTicks()
        if (current_time - a.player.last_frame_time) >= u32(a.player.frame_time) {
            a.player.current_frame += 1
            if a.player.current_frame >= len(a.player.textures) {
                a.player.current_frame = 0 // Wrap frame index
            }
            a.player.last_frame_time = current_time // Update last frame time
        }


        //drawing
        sdl.RenderClear(a.renderer)
        sdl.RenderCopy(a.renderer, a.background, nil, nil)
        sdl.RenderCopy(a.renderer, a.player.textures[a.player.current_frame], nil, &a.player.player_render)

        sdl.RenderPresent(a.renderer)

        sdl.Delay(1000 / FRAMERATE_TARGET)
    }
}

main :: proc() {
    exit_status := 0
    app: App

    defer os.exit(exit_status)
    defer app_cleanup(&app)

    if !initialize(&app) {
        exit_status = 1
        return
    }

    if !load_media(&app) {
        exit_status = 1
        return
    }


    app_run(&app)
}

// [] Colors & Icons
// [] Text Rendering
// [] Programmatic Animation
// [] Sprite Animation
// [] Audio