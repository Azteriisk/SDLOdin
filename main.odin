// How this thing works:
//  - Create SDL Context
//  - Create a Window
//  - Create a Renderer
//  - Create Clean-Up/Destruction Methods for anything allocating memory on the heap
//  - Clear & Present Render to Renderer
//  - Poll predefined events looking for changes
//  - Switch through present event types to handle requests appropriately
//  - Initialize SDL2 Image Context
//  - Creates graphics layers with SDL RenderCopies
//  - Randomize background color on spacebar click with built-in randomize function with max param
//  - Creates a surface texture for icon 

package main

import "core:fmt"
import "core:os"
import "core:math/rand"
import sdl "vendor:sdl2"
import img "vendor:sdl2/image"
import str "core:strings"
import time "core:time" // Import the time package
import ttf "vendor:sdl2/ttf"

SDL_FLAGS :: sdl.INIT_EVERYTHING
IMG_FLAGS :: img.INIT_PNG | img.INIT_JPG
WINDOW_FLAGS :: sdl.WINDOW_SHOWN
RENDER_FLAGS :: sdl.RENDERER_ACCELERATED

WINDOW_TITLE :: "SDL Application"
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 600
FRAMERATE_TARGET :: 90 // Idk if this actually works, but it doesn't *not* work

FONT_SIZE :: 80

App :: struct {
    window:     ^sdl.Window,
    renderer:   ^sdl.Renderer,
    icon: ^sdl.Surface,
    event:      sdl.Event,
    player:     Player,
    text:   cstring,
    text_rect: sdl.Rect,
    font_color: sdl.Color,
    text_render: ^sdl.Texture,
}

Player :: struct {
    textures:      [4]^sdl.Texture, // Array to hold sprite textures
    current_frame: int,            // Current frame index
    frame_time:    f32,            // Time per frame
    player_render: sdl.Rect,         // Player render rectangle
    last_frame_time: u32,          // Time of the last frame update
    anim_fps: f32
}

app_cleanup :: proc(a: ^App) {
    if a != nil {
        // Texture cleanup
        if a.text_render != nil {sdl.DestroyTexture(a.text_render)}

        if a.player.textures[0] != nil {
            for texture in a.player.textures {
                sdl.DestroyTexture(texture)
            }
        }

        // Cleanup for Systems/Subsystems
        if a.icon != nil {sdl.FreeSurface(a.icon)}
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

    if ttf.Init() != 0 {
        fmt.eprintfln("Error Initializing SDL2 TTF: %s", sdl.GetError())
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
    if a.renderer == nil {
        fmt.eprintfln("Error Creating Renderer: %s", sdl.GetError())
        return false
    }
    // Creating the Icon
    icon_surf := img.Load("images/icon.png")
    if icon_surf == nil {
        fmt.eprintfln("Error Loading Icon: %s", img.GetError())
        return false
    }

    sdl.SetWindowIcon(a.window, icon_surf)
    sdl.FreeSurface(icon_surf)

    return true
}

load_media :: proc(a: ^App) -> bool {
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
    a.player.anim_fps = 4
    a.player.current_frame = 0
    a.player.frame_time = 1000 / a.player.anim_fps; //
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

    font := ttf.OpenFont("fonts/PixelGame.ttf", FONT_SIZE)
    if font == nil {
        fmt.eprintfln("Error Loading Font File: %s", ttf.GetError())
        return false
    }

    a.text = "Odin"
    a.font_color = sdl.Color{255,255,255,255}

    font_surf := ttf.RenderText_Blended(font, a.text, a.font_color)
    ttf.CloseFont(font)
    if font_surf == nil {
        fmt.eprintfln("Error Creating Text Surface: %s", ttf.GetError())
        return false
    }

    a.text_rect.w = font_surf.w
    a.text_rect.h = font_surf.h
    
    a.text_render = sdl.CreateTextureFromSurface(a.renderer, font_surf)
    sdl.FreeSurface(font_surf)
    if a.text_render == nil {
        fmt.eprintfln("Error Creating Texture from Surface: %s", sdl.GetError())
        return false
    }

    return true
}

rand_background :: proc(a: ^App) {
    sdl.SetRenderDrawColor(a.renderer, u8(rand.int31_max(256)), u8(rand.int31_max(256)), u8(rand.int31_max(256)), 255)
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
                    case .SPACE:
                        rand_background(a)
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
        sdl.RenderCopy(a.renderer, a.player.textures[a.player.current_frame], nil, &a.player.player_render)
        sdl.RenderCopy(a.renderer, a.text_render, nil, &a.text_rect)

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

// [✅] Colors & Icons
// [] Text Rendering
// [] Programmatic Animation aka Movement for game
// [✅] Sprite Animation
// [] Audio 