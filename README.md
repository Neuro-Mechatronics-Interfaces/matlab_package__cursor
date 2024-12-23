# Cursor #

Simple `MATLAB` Cursor class to log/display 2D position of virtual cursor that implements acceleration, velocity, and position states. Polling the joystick using basic Windows `c` API modified from the code available in [Psychtoolbox](https://github.com/Psychtoolbox-3/Psychtoolbox-3/blob/master/Psychtoolbox/PsychContributed/WinJoystickMex.c).  

## Features
- Smooth and configurable joystick-based cursor control.
- Logging of joystick input to a binary file.
- Visualization of cursor movement in 2D space.
- Automatic compilation of `WinJoystickMex` if not present.

## Installation
Add this as a submodule to your existing project- but make sure to put it in a folder named `+cursor`
```bat
git submodule add git@github.com:Neuro-Mechatronics-Interfaces/matlab_package__cursor.git +cursor
git submodule update --init --recursive
```

After adding the submodule, your MATLAB workspace (`project`, below) should look like this:  

```
project/
├── +cursor/
|   ├── createButtonListener.m % Utility function to generate listeners for indexed button events.
│   ├── @Cursor/ 
|   |   ├──Cursor.m           % Cursor class definition
│   |   ├── WinJoystickMex.c  % Source file for the joystick MEX function
│   ├── @GameContainer/ 
|   |   ├──GameContainer.m    % Container class definition
│   ├── @ButtonEventData/ 
|       ├──ButtonEventData.m  % EventData definition for when BUTTON1-BUTTON8 is pressed. 
```

## Usage

### Basic Setup

1. **Create a `Cursor` object**: Initialize the class to handle the joystick-based cursor.
2. **Enable Logging**: Configure the logging to output a `.dat` file.
3. **Start Sampling and View Cursor**: Launch the cursor visualization and joystick sampling.
4. **Stop Sampling**: Stop the sampling process gracefully.

### Notes

1. The `WinJoystickMex.c` file must be present in the `@Cursor` folder.
2. MATLAB automatically compiles the `WinJoystickMex` file if not already compiled.
3. Ensure `WinJoystickMex.c` compiles successfully with the required libraries (`-lwinmm` on Windows).

### Dependencies

- MATLAB R2022b or later (tested).
- A compatible joystick connected to the system.
- Compiler installed and configured for MEX files on your system.

---

### Troubleshooting

#### Error: "MEX file is missing and source file is not available."
- Ensure the `WinJoystickMex.c` file is present in the `@Cursor` folder.
- Ensure MATLAB can access a compatible C compiler.

#### Error: "Integers can only be combined with integers of the same class."
- This typically occurs if the joystick data is not correctly processed. Ensure the `Cursor` class implementation matches the required logic for handling joystick data.