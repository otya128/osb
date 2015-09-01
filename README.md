# otyaSMILEBASIC
SMILEBASIC 3.x互換BASIC

<img src="https://raw.githubusercontent.com/otya128/otyaSMILEBASIC/master/screenshots/GAME4SHOOTER.png">

## 速度
実行環境によるものの3DSよりは速い。
SYS/EX8TECDEMOのSPEED TEST括弧は旧3DS

|ないよう|スコア(はやいほど かずが おおきい)|
|---|---|
|たしざん|732293(153860)|
|PRINTぶん|351160(34391)|
|スプライトいどう|623998(67960)|
|ラインびょうが|394808(17720)|

# ビルド方法
```sh
git clone git@github.com:otya128/otyaSMILEBASIC.git
cd otyaSMILEBASIC
dub run
```

## コンパイルするのに必要なもの
+ Dコンパイラ
+ dub
+ DerelictSDL2
+ DerelictGL3
+ curl

## 実行時に必要なもの
+ SDL2

## 実装機能
動くコード例
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
