[Japanese](README-ja.md)
# otyaSMILEBASIC
SmileBASIC 3.x(3DS/WiiU) Compatible BASIC

<img src="https://raw.githubusercontent.com/otya128/otyaSMILEBASIC/master/screenshots/GAME4SHOOTER.png">

## Download
[Windows-x86 master build](https://ci.appveyor.com/api/projects/otya128/otyasmilebasic/artifacts/otyasmilebasic.zip)

## LICENSE
MIT

# How to build
```sh
git clone git@github.com:otya128/otyaSMILEBASIC.git
cd otyaSMILEBASIC
dub run
```

## Dependency:build
+ D compiler
+ dub
+ DerelictSDL2
+ DerelictGL3
+ curl

## Dependency:run
+ SDL2

## implemented function
Example code
```
FOR I=0 TO 100
 IF I MOD 3==0 AND I MOD 5==0 THEN
  ?"FIZZBUZZ"
 ELSE
  IF I MOD 3==0 THEN
   ?"FIZZ"
  ELSE
   IF I MOD 5==0 THEN
    ?"BUZZ"
   ELSE
    ?I
   ENDIF
  ENDIF
 ENDIF
NEXT
DEF FACT(N)
 IF N<=1 THEN RETURN 1
 RETURN N*FACT(N-1)
END
DEF TEST2 A,B,C OUT D,E,F
 D=A
 E=B
 F=C
END
```
