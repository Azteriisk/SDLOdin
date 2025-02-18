// How this thing works:
//	- Create SDL Context
//	- Create a Window
//	- Create a Renderer
//	- Create Clean-Up/Destruction Methods for the Window & Renderer
//	- Clear & Present Render to Renderer
//	- Poll predefined events looking for changes
//	- Switch through present event types to handle requests appropriately
//	- Initialize SDL2 Image Context

package main

import "core:fmt"
import "core:os"
import sdl "vendor:sdl2"
import img "vendor:sdl2/image"

SDL_FLAGS :: sdl.INIT_EVERYTHING
IMG_FLAGS :: img.INIT_PNG | img.INIT_JPG
WINDOW_FLAGS :: sdl.WINDOW_SHOWN
RENDER_FLAGS :: sdl.RENDERER_ACCELERATED

WINDOW_TITLE :: "SDL Application"
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 600
FRAMERATE_TARGET :: 120

App :: struct {
	window:   ^sdl.Window,
	renderer: ^sdl.Renderer,
	event:    sdl.Event,
}

app_cleanup :: proc(a: ^App) {
	if a != nil {
		if a.renderer != nil {sdl.DestroyRenderer(a.renderer)}
		if a.window != nil {sdl.DestroyWindow(a.window)}

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

	if a.renderer == nil {
		fmt.eprintfln("Error Creating Renderer: %s", sdl.GetError())
		return false
	}
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

		//drawing
		sdl.RenderClear(a.renderer)
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
	app_run(&app)
}


// finish implementing SDL2 Image for hardware accelerated textures
// look into default SDL supported Bitmap images potential performance impact for sprite rendering
