/*------------------------------------------------------------------------------
WinJoystickMex.c -- A simple Matlab/Octave MEX file for query of joysticks on Microsoft Windows.

On Matlab, compile with:

mex -v -g WinJoystickMex.c winmm.lib

On Octave, compile with:

mex -v -g WinJoystickMex.c -lwinmm

------------------------------------------------------------------------------

    WinJoystickMex.c is Copyright (C) 2009-2012 Mario Kleiner

    This program is licensed under the MIT license.

	A copy of the license can be found in the License.txt file inside the
	Psychtoolbox-3 top level folder.
------------------------------------------------------------------------------*/

/* Windows includes: */
#include <windows.h>
#include <stdint.h>
#include <math.h>

/* Matlab includes: */
#include "mex.h"

#define MAX_VAL 65535.0

/* This is the main entry point from Matlab: */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[])
{
	JOYINFO joy;	// Struct into which joystick state is returned.
	MMRESULT rc;	// Return code of function.
	unsigned int cmd;
    UINT wNumDevs;
	
	// Get our name for output:
	const char* me = mexFunctionName();

	if(nrhs < 1) {
		mexPrintf("WinJoystickMex: A simple Matlab/Octave MEX file for query of simple joysticks on Microsoft Windows\n\n");
		mexPrintf("(C) 2009-2012 by Mario Kleiner -- Licensed to you under the MIT license.\n");
		mexPrintf("This file is part of Psychtoolbox-3 but should also work independently.\n");
		mexPrintf("\n");
		mexPrintf("Usage:\n\n");
		mexPrintf("[x, y, buttons] = %s(joystickId);\n", me);
		mexPrintf("- Query joystick device 'joystickId'. This can be any number between 0 and 15.\n");
		mexPrintf("0 is the first connected joystick, 1 the 2nd, etc...\n");
		mexPrintf("x, y are the current x, y directions of the joystick (-1 is left/down; +1 is right/up respectively).\n");
		mexPrintf("buttons is a uint8 bit-packed value, with button-1 pressed mapped as 1 on bit-0 (LSB).\n\n\n");
        return;
	}
	
	/* First argument must be the joystick id: */
	cmd = (unsigned int) mxGetScalar(prhs[0]);

	/* Call joystick function: */
	if ((rc = joyGetPos((UINT) cmd, &joy)) != JOYERR_NOERROR) {
		switch((int) rc) {
			case MMSYSERR_NODRIVER:
                mexPrintf("For failed joystick call with 'joystickId' = %i.\n", cmd);
				mexErrMsgTxt("The joystick driver is not present or active on this system! [MMSYSERR_NODRIVER]");
			break;
			
			case JOYERR_NOCANDO:
                mexPrintf("For failed joystick call with 'joystickId' = %i.\n", cmd);
				mexErrMsgTxt("Some system service for joystick support is not present or active on this system! [JOYERR_NOCANDO]");
			break;
			
			case MMSYSERR_INVALPARAM:
			case JOYERR_PARMS:
				plhs[0] = mxCreateNumericMatrix(1, 1, mxINT8_CLASS, mxREAL);
                *(int8_t *)mxGetData(plhs[0]) = 0;
                plhs[1] = mxCreateNumericMatrix(1, 1, mxINT8_CLASS, mxREAL);
                *(int8_t *)mxGetData(plhs[1]) = 0;
                plhs[2] = mxCreateNumericMatrix(1, 1, mxUINT8_CLASS, mxREAL);
                *(uint8_t *)mxGetData(plhs[2]) = 0;
                return;
                // mexErrMsgTxt("Invalid 'joystickId' passed! [MMSYSERR_INVALPARAM or JOYERR_PARMS]");
			break;

			case JOYERR_UNPLUGGED:
                mexPrintf("For failed joystick call with 'joystickId' = %i.\n", cmd);
				mexErrMsgTxt("The specified joystick is not connected to the system! [JOYERR_UNPLUGGED]");
			break;

			default:
                mexPrintf("For failed joystick call with 'joystickId' = %i.\n", cmd);
				mexPrintf("Return code of failed joystick call is %i.\n", rc);
				mexErrMsgTxt("Unknown error! See return code above.");
		}
	}

	// Normalize X pos:
    plhs[0] = mxCreateNumericMatrix(1, 1, mxINT8_CLASS, mxREAL);
    *(int8_t *)mxGetData(plhs[0]) = (int8_t)round((((double)joy.wXpos) / MAX_VAL) * 2.0 - 1.0);

    // Normalize Y pos:
    plhs[1] = mxCreateNumericMatrix(1, 1, mxINT8_CLASS, mxREAL);
    *(int8_t *)mxGetData(plhs[1]) = (int8_t)round((((double)joy.wYpos) / MAX_VAL) * -2.0 + 1.0);

    // Return 8-bit packed button state:
    plhs[2] = mxCreateNumericMatrix(1, 1, mxUINT8_CLASS, mxREAL);
    uint8_t *out = (uint8_t *)mxGetData(plhs[2]);
    *out = 0; // Initialize to 0

    // Set each bit according to the button state:
    *out |= ((joy.wButtons & JOY_BUTTON1) ? 1 : 0) << 0; // Button 1
    *out |= ((joy.wButtons & JOY_BUTTON2) ? 1 : 0) << 1; // Button 2
    *out |= ((joy.wButtons & JOY_BUTTON3) ? 1 : 0) << 2; // Button 3
    *out |= ((joy.wButtons & JOY_BUTTON4) ? 1 : 0) << 3; // Button 4
    *out |= ((joy.wButtons & JOY_BUTTON5) ? 1 : 0) << 4; // Button 5
    *out |= ((joy.wButtons & JOY_BUTTON6) ? 1 : 0) << 5; // Button 6
    *out |= ((joy.wButtons & JOY_BUTTON7) ? 1 : 0) << 6; // Button 7
    *out |= ((joy.wButtons & JOY_BUTTON8) ? 1 : 0) << 7; // Button 8


	// Done.
	return;
}