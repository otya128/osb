module otya.smilebasic.petitcomputer;
import derelict.sdl2.sdl;
class PetitComputer
{
    this()
    {
    }
    void run()
    {
        DerelictSDL2.load();
        SDL_Init(SDL_INIT_VIDEO);
        SDL_Window* window = SDL_CreateWindow("SMILEBASIC", SDL_WINDOWPOS_UNDEFINED,
                                              SDL_WINDOWPOS_UNDEFINED, 400, 240,
                                              SDL_WINDOW_SHOWN);
        SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, 0);
        while (true)
        {
            SDL_Event event;
            SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
            SDL_RenderClear(renderer);
            SDL_RenderPresent(renderer);
            while (SDL_PollEvent(&event))
            {
                switch (event.type)
                {
                    case SDL_KEYDOWN,SDL_QUIT:
                        return;

                    default:
                        break;
                }
            }
        }
        SDL_DestroyWindow(window);
        SDL_Quit();
    }
}