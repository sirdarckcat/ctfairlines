/*******************************************************************
 *                                                                 *
 *                        Using SDL With OpenGL                    *
 *                                                                 *
 *                    Tutorial by Kyle Foley (sdw)                 *
 *                                                                 *
 * http://gpwiki.org/index.php/SDL:Tutorials:Using_SDL_with_OpenGL *
 *                                                                 *
 *******************************************************************/

#include "SDL/SDL.h"
#include "SDL/SDL_opengl.h"

#include <stdio.h>

#include "receiver.h"
#include "scopedparallelexecutor.h"
#include "defaultlogger.h"
#include "ids.h"

void wait();

using namespace SCS;

const unsigned char required_sw_revision = 1;



void wait()
{
    std::cin.clear();
    std::cin.ignore(std::cin.rdbuf()->in_avail());
    std::cin.get();
}

void loadTexture(const char* filename, GLuint* texture)
{
    SDL_Surface *surface; // Gives us the information to make the texture

    if ( (surface = SDL_LoadBMP(filename)) ) {

        // Check that the image's width is a power of 2
        if ( (surface->w & (surface->w - 1)) != 0 ) {
            printf("warning: image.bmp's width is not a power of 2\n");
        }

        // Also check if the height is a power of 2
        if ( (surface->h & (surface->h - 1)) != 0 ) {
            printf("warning: image.bmp's height is not a power of 2\n");
        }

        // Have OpenGL generate a texture object handle for us
        glGenTextures( 1, texture );

        // Bind the texture object
        glBindTexture( GL_TEXTURE_2D, *texture );

        // Set the texture's stretching properties
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );

        // Edit the texture object's image data using the information SDL_Surface gives us
        glTexImage2D( GL_TEXTURE_2D, 0, 3, surface->w, surface->h, 0,
                     GL_BGR, GL_UNSIGNED_BYTE, surface->pixels );
    }
    else {
        printf("SDL could not load image.bmp: %s\n", SDL_GetError());
        SDL_Quit();
    }
    // Free the SDL_Surface only if it was successfully created
    if ( surface ) {
        SDL_FreeSurface( surface );
    }
}

int main(int argc, char *argv[])
{
    SDL_Surface *screen;

    // Slightly different SDL initialization
    if ( SDL_Init(SDL_INIT_VIDEO) != 0 ) {
        printf("Unable to initialize SDL: %s\n", SDL_GetError());
        return 1;
    }

    SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 ); // *new*

    screen = SDL_SetVideoMode( 128, 128, 16, SDL_OPENGL ); // *changed*
    if ( !screen ) {
        printf("Unable to set video mode: %s\n", SDL_GetError());
        return 1;
    }

    // Set the OpenGL state after creating the context with SDL_SetVideoMode

    glClearColor( 0, 0, 0, 0 );

    glEnable( GL_TEXTURE_2D ); // Need this to display a texture

    glViewport( 0, 0, 128, 128 );

    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();

    glOrtho( 0, 128, 128, 0, -1, 1 );

    glMatrixMode( GL_MODELVIEW );
    glLoadIdentity();

    // Load the OpenGL texture

    GLuint foreground; // Texture object handle
    loadTexture("Needle.bmp", &foreground);

    GLuint background; // Texture object handle
    loadTexture("Gauge.bmp", &background);

    // Clear the screen before drawing
    glClear( GL_COLOR_BUFFER_BIT );

    // Bind the texture to which subsequent calls refer to
    glBindTexture( GL_TEXTURE_2D, background );

    glBegin( GL_QUADS );
    // Top-left vertex (corner)
    glTexCoord2i( 0, 0 );
    glVertex3f( 0, 0, 0 );

    // Bottom-left vertex (corner)
    glTexCoord2i( 1, 0 );
    glVertex3f( 128, 0, 0 );

    // Bottom-right vertex (corner)
    glTexCoord2i( 1, 1 );
    glVertex3f( 128, 128, 0 );

    // Top-right vertex (corner)
    glTexCoord2i( 0, 1 );
    glVertex3f( 0, 128, 0 );
    glEnd();



    int GaugeLeft = 64; int GaugeBottom = 128;

    /// Setup our needle relative to the gauge
    int    NeedleLeft = GaugeLeft-3;
    int    NeedleRight = NeedleLeft + 6;
    int    NeedleBottom = GaugeBottom - 68.0;
    int    NeedleTop = NeedleBottom + 45.0;
    int    NeedleTranslationX = NeedleLeft + ((NeedleRight - NeedleLeft) / 2);
    int    NeedleTranslationY = NeedleBottom+(4);

    glPushMatrix();
    glTranslatef(NeedleTranslationX, NeedleTranslationY, 0.0f);
    glRotatef(1.0f, 0.0f , 0.0f, -1.0f);
    glTranslatef(-NeedleTranslationX, -NeedleTranslationY, 0.0f);

    glBindTexture( GL_TEXTURE_2D, foreground );

    glBegin( GL_QUADS );
    // Top-left vertex (corner)
    glTexCoord2i( 1, 0 );
    glVertex3f( NeedleRight, NeedleBottom, 0 );

    // Bottom-left vertex (corner)
    glTexCoord2i( 0, 0 );
    glVertex3f( NeedleLeft, NeedleBottom, 0 );

    // Bottom-right vertex (corner)
    glTexCoord2i( 0, 1 );
    glVertex3f( NeedleLeft, NeedleTop, 0 );

    // Top-right vertex (corner)
    glTexCoord2i( 1, 1 );
    glVertex3f( NeedleRight, NeedleTop, 0 );
    glEnd();
    glPopMatrix();

    SDL_GL_SwapBuffers();
    Receiver r(required_sw_revision);
    float airspeed;
    r.requestData(IAS_M_S::Id(), &airspeed);
    ScopedParallelExecutor exec(boost::bind(&Receiver::run, &r, false), 100);

    int count = 315;
    while (count >= 45) {

        SDL_Delay(100);
        glClear( GL_COLOR_BUFFER_BIT );
        // Bind the texture to which subsequent calls refer to
        glBindTexture( GL_TEXTURE_2D, background );

        glBegin( GL_QUADS );
        // Top-left vertex (corner)
        glTexCoord2i( 0, 0 );
        glVertex3f( 0, 0, 0 );

        // Bottom-left vertex (corner)
        glTexCoord2i( 1, 0 );
        glVertex3f( 128, 0, 0 );

        // Bottom-right vertex (corner)
        glTexCoord2i( 1, 1 );
        glVertex3f( 128, 128, 0 );

        // Top-right vertex (corner)
        glTexCoord2i( 0, 1 );
        glVertex3f( 0, 128, 0 );
        glEnd();
        glPushMatrix();
        glTranslatef(NeedleTranslationX, NeedleTranslationY, 0.0f);
        std::cout << "airspeed" << airspeed << std::endl;
        glRotatef(((45-315)/100.0*airspeed+315), 0.0f , 0.0f, -1.0f);
        glTranslatef(-NeedleTranslationX, -NeedleTranslationY, 0.0f);
        glBindTexture( GL_TEXTURE_2D, foreground );
        glBegin( GL_QUADS );
        // Top-left vertex (corner)
        glTexCoord2i( 1, 0 );
        glVertex3f( NeedleRight, NeedleBottom, 0 );

        // Bottom-left vertex (corner)
        glTexCoord2i( 0, 0 );
        glVertex3f( NeedleLeft, NeedleBottom, 0 );

        // Bottom-right vertex (corner)
        glTexCoord2i( 0, 1 );
        glVertex3f( NeedleLeft, NeedleTop, 0 );

        // Top-right vertex (corner)
        glTexCoord2i( 1, 1 );
        glVertex3f( NeedleRight, NeedleTop, 0 );
        glEnd();
        glPopMatrix();

        SDL_GL_SwapBuffers();
        count--;
    }
    //SDL_Delay(3000);

    // Now we can delete the OpenGL texture and close down SDL
    glDeleteTextures( 1, &foreground );
    glDeleteTextures( 1, &background );

    SDL_Quit();
    std::cout << "Bye, bye" << std::endl;
    return 0;
}
