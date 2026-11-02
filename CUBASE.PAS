{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/office-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal
  @description: Clone de l'application Cubase
}

Program CUBASE;

{$IFNDEF FPC}
 {$M 32768,0,655360}
{$ENDIF}

Uses {$IFDEF FPC}
      DOS,Crt,PtcGraph,PtcCrt,PtcMouse
     {$ELSE}
      DOS,Crt,Graph
     {$ENDIF};

{$IFDEF MSWINDOWS}
{ Declarations Win32/Win64 locales : aucune unite supplementaire, les DLL
  sont celles du systeme Windows. }
 Type
  DWORD = LongWord;
  HWAVEOUT = PtrUInt;
  PHWAVEOUT = ^HWAVEOUT;
  TWaveFormatEx = Packed Record
   wFormatTag, nChannels: Word;
   nSamplesPerSec, nAvgBytesPerSec: DWORD;
   nBlockAlign, wBitsPerSample, cbSize: Word;
  End;
  PWaveFormatEx = ^TWaveFormatEx;
  PWaveHdr = ^TWaveHdr;
  TWaveHdr = Packed Record
   lpData: PChar;
   dwBufferLength, dwBytesRecorded: DWORD;
   dwUser: PtrUInt;
   dwFlags, dwLoops: DWORD;
   lpNext: PWaveHdr;
   reserved: PtrUInt;
  End;

 Const
  WAVE_FORMAT_PCM = 1;
  WAVE_MAPPER = DWORD($FFFFFFFF);
  CALLBACK_NULL = 0;
  MMSYSERR_NOERROR = 0;
  WHDR_DONE = 1;
  WHDR_PREPARED = 2;
  WHDR_INQUEUE = 16;

 Function waveOutOpen(Handle: PHWAVEOUT; Device: DWORD; Format: PWaveFormatEx;
                      Callback, Instance: PtrUInt; Flags: DWORD): DWORD;
 stdcall;
 external 'winmm.dll' name 'waveOutOpen';

 Function waveOutPrepareHeader(Handle: HWAVEOUT; Header: PWaveHdr; Size: DWORD): DWORD;
 stdcall; external 'winmm.dll' name 'waveOutPrepareHeader';

 Function waveOutUnprepareHeader(Handle: HWAVEOUT; Header: PWaveHdr; Size: DWORD): DWORD;
 stdcall; external 'winmm.dll' name 'waveOutUnprepareHeader';

 Function waveOutWrite(Handle: HWAVEOUT; Header: PWaveHdr; Size: DWORD): DWORD;
 stdcall; external 'winmm.dll' name 'waveOutWrite';

 Function waveOutReset(Handle: HWAVEOUT): DWORD;
 stdcall;
 external 'winmm.dll' name 'waveOutReset';

 Function waveOutClose(Handle: HWAVEOUT): DWORD;
 stdcall;
 external 'winmm.dll' name 'waveOutClose';

 Function GetTickCount: DWORD;
 stdcall; external 'kernel32.dll' name 'GetTickCount';

 Procedure Sleep(Milliseconds: DWORD);
 stdcall; external 'kernel32.dll' name 'Sleep';
{$ENDIF}

{ ====================================================================== }
{                              CONSTANTES                                }
{ ====================================================================== }

Const
 VERSION_TEXT = '1.0';
 OPTFILE      = 'CUBASE.OPT';
 UNDOFILE     = 'CUBASE.UND';
 SCR_W        = 640;
 SCR_H        = 480;
 MENU_H       = 18;
 TB_H         = 16;
 INK          = 0;
 PAPER        = 15;

 PPQ     = 192;        { resolution : 192 parties par noire }
 NTRK    = 64;         { pistes par arrangement }
 MAXPART = 300;        { parties (parts) }
 MAXEV   = 1000;       { evenements par partie }
 NTEMPO  = 64;         { changements de tempo (piste maitre) }
 NQUA    = 10;
 NINST   = 16;
 NDRUM   = 16;
 {$IFDEF FPC}
 POOL_EV = 40000;
 {$ELSE}
 POOL_EV = 12000;
 {$ENDIF}

 { Vues }
 V_ARR    = 1;
 V_KEY    = 2;
 V_SCORE  = 3;
 V_GRID   = 4;
 V_DRUM   = 5;
 V_MASTER = 6;

 { Types d'evenements }
 EK_NOTE  = 1;
 EK_CTRL  = 2;
 EK_PROG  = 3;
 EK_BEND  = 4;
 EK_CHANP = 5;
 EK_POLYP = 6;

 { Codes de touches : caractere = ord ; etendue = 256 + code }
 K_ESC    = 27;
 K_ENTER  = 13;
 K_BKSP   = 8;
 K_TAB    = 9;
 K_UP     = 328;
 K_DOWN   = 336;
 K_LEFT   = 331;
 K_RIGHT  = 333;
 K_HOME   = 327;
 K_END    = 335;
 K_PGUP   = 329;
 K_PGDN   = 337;
 K_INS    = 338;
 K_DEL    = 339;
 K_F1     = 315;
 K_F10    = 324;
 K_F11    = 389;
 K_F12    = 390;
 K_STAB   = 271;

 { Geometrie ecran }
 TB_Y   = 18;           { barre de titre de la fenetre }
 P1_Y   = 35;           { rangee de parametres }
 P1_B   = 51;
 HD_Y   = 53;           { en-tete de colonnes / regle }
 HD_B   = 66;
 R0_Y   = 68;           { premiere piste }
 ROWH   = 15;
 VISR   = 22;
 R0_B   = R0_Y+ROWH*VISR-1;
 HS_Y   = 399;          { ascenseur horizontal }
 HS_B   = 414;
 TR_Y   = 417;          { tableau de transport }
 LW     = 224;          { largeur de la liste de pistes }
 AR_X0  = 224;          { zone des parties }
 AR_X1  = 622;
 VS_X   = 624;          { ascenseur vertical }

 NSNAP  = 6;
 NTOOL  = 6;

{ ====================================================================== }
{                                TYPES                                   }
{ ====================================================================== }

Type
 TEvt = Packed Record
  T,Len : LongInt;
  Kind,D1,D2 : Byte;
  Sel : Boolean;
 End;
 PEvArr = ^TEvArr;
 TEvArr = Array[1..MAXEV] Of TEvt;

 TPlayPar = Packed Record
  Trans,Vel,Dly,LenP,Comp,Prg,Vol : Integer;
 End;

 TTrack = Packed Record
  Name  : String[12];
  Instr : String[10];
  Chan  : Byte;                    { 1..16 ; 0 = tous }
  Outp  : Byte;                    { 0 Atari, 1 MIDI 1, 2 MIDI 2 }
  Mute,Solo,Drum : Boolean;
  Filt  : Byte;                    { bits a 1 = filtre }
  PP    : TPlayPar;
 End;

 TPart = Record
  Used,Sel,Mute : Boolean;
  Trk  : Byte;
  Name : String[12];
  Start,Stop : LongInt;
  Cnt,Cap : Integer;
  Ev   : PEvArr;
  PP   : TPlayPar;
  Cur  : Integer;
 End;

 TTempoEv = Packed Record
  T : LongInt;
  V : Integer;                     { tempo x 10 }
 End;

 TEvent = Record
  { 0 rien, 1 touche, 2 bouton bas, 3 bouton haut, 4 mouvement }
  Kind : Byte;
  Key  : Word;
  X,Y,B: LongInt;
 End;

 TSonHdr = Packed Record
  ID : Array[1..4] Of Char;
  Ver : Word;
  Tempo : Integer;
  LocL,LocR : LongInt;
  SigN,SigD : Byte;
  Flags : Array[1..16] Of Byte;
  NP,NT : Word;
 End;
 TPartHdr = Packed Record
  Trk : Byte;
  Name : String[12];
  Start,Stop : LongInt;
  Cnt : Word;
  Mute : Boolean;
  PP : TPlayPar;
 End;

 TMsg = Record
  T : LongInt;
  Ord1,S,D1,D2,Cnt : Byte;
 End;
 PMsgArr = ^TMsgArr;
 TMsgArr = Array[1..2400] Of TMsg;
 PByteArr = ^TByteArr;
 TByteArr = Array[0..16000] Of Byte;

Var
 Lang : Integer;       { 0 anglais, 1 francais, 2 allemand }

Function T3(Const En,Fr,De: String): String;
Begin
 Case Lang Of
  0: T3:=En;
  2: T3:=De;
 Else T3:=Fr;
 End;
End;

{ 'EN~FR~DE' : extrait la partie N }
Function Part3(Const S: String; N: Integer): String;
Var I,K: Integer; R: String;
Begin
 R:='';K:=0;
 For I:=1 To Length(S) Do
  If S[I]='~' Then Inc(K) Else If K=N Then R:=R+S[I];
 If (R='') And (N<>0) Then Part3:=Part3(S,0) Else Part3:=R;
End;

Function IntStr(N: LongInt): String;
Var S: String;
Begin
 Str(N,S);
 IntStr:=S;
End;

Function Upper(S: String): String;
Var I: Integer;
Begin
 For I:=1 To Length(S) Do S[I]:=UpCase(S[I]);
 Upper:=S;
End;

Function Min2(A,B: LongInt): LongInt;
Begin
 If A<B Then Min2:=A Else Min2:=B;
End;

Function Max2(A,B: LongInt): LongInt;
Begin
 If A>B Then Max2:=A Else Max2:=B;
End;

Function Clamp(V,A,B: LongInt): LongInt;
Begin
 If V<A Then V:=A;
 If V>B Then V:=B;
 Clamp:=V;
End;

Function Pad2(N: LongInt): String;
Var S: String;
Begin
 Str(N,S);
 If Length(S)<2 Then S:='0'+S;
 Pad2:=S;
End;

Function PadL(Const S: String; W: Integer): String;
Var R: String;
Begin
 R:=S;
 While Length(R)<W Do R:=' '+R;
 PadL:=R;
End;

Function ToInt(Const S: String): LongInt;
Var V: LongInt; C: Integer;
Begin
 Val(S,V,C);
 If C<>0 Then V:=0;
 ToInt:=V;
End;

Function FileExists(Const N: String): Boolean;
Var F: File;
Begin
 {$I-}
 Assign(F,N);
 Reset(F,1);
 {$I+}
 If IOResult=0 Then Begin Close(F);FileExists:=True;End Else FileExists:=False;
End;

Function ShortName(Const N: String): String;
Var I: Integer;
Begin
 I:=Length(N);
 While (I>0) And (N[I]<>'\') And (N[I]<>'/') And (N[I]<>':') Do Dec(I);
 ShortName:=Copy(N,I+1,255);
End;

Function AddExt(Const N,Ext: String): String;
Var S: String;
Begin
 S:=N;
 If Pos('.',ShortName(S))=0 Then S:=S+'.'+Ext;
 AddExt:=S;
End;
{ ====================================================================== }
{                  GRAPHIQUE / SOURIS (squelette)                        }
{ ====================================================================== }

Procedure InitializeGraphics;
Var
 Driver, Mode: Integer;
 ErrCode: Integer;
Begin
 {$IFDEF FPC}
  Driver:=VGA;
  Mode:=VGAHi;
 {$ELSE}
  Driver:=Detect;
  Mode:=VGAHi;
 {$ENDIF}
 InitGraph(Driver,Mode,'');
 ErrCode:=GraphResult;
 If ErrCode=grOk Then Begin
  SetColor(White);
  SetLineStyle(0,0,1);
 End
  Else
 Begin
  WriteLn('Erreur graphique : ',GraphErrorMsg(ErrCode));
  Halt;
 End;
End;

Var
 MX,MY,MB,LastB : LongInt;
 PrevMX,PrevMY  : LongInt;

{$IFNDEF FPC}
 Function MouseDriverFound: Boolean;
 Var
  Regs: Registers;
 Begin
  Regs.AX := 0;
  Intr($33, Regs);
  MouseDriverFound := Regs.AX = $FFFF;
 End;

 Procedure ShowMouse;
 Var
  Regs: Registers;
 Begin
  Regs.AX := $0001;
  Intr($33, Regs);
 End;

 Procedure HideMouse;
 Var
  Regs: Registers;
 Begin
  Regs.AX := $0002;
  Intr($33, Regs);
 End;

 Procedure GetMouseState(Var X, Y, Button: LongInt);
 Var
  Regs: Registers;
 Begin
  Regs.AX := $0003;
  Intr($33, Regs);
  Button := Regs.BX;
  X := Regs.CX;
  Y := Regs.DX;
 End;
{$ELSE}
 { Sous PtcMouse le curseur est invisible : fleche logicielle avec
   sauvegarde de l'arriere-plan }
 Var
  CurSaved,CurShown : Boolean;
  CurBuf : Pointer;
  CurSz  : LongInt;
  CurX,CurY : LongInt;

 Function MouseDriverFound: Boolean;
 Begin
  MouseDriverFound := True;
 End;

 Procedure CursorErase;
 Begin
  If CurSaved Then Begin
   PutImage(CurX,CurY,CurBuf^,NormalPut);
   FreeMem(CurBuf,CurSz);
   CurSaved:=False;
  End;
 End;

 Procedure CursorDraw(X,Y: LongInt);
 Var Pt: Array[1..7] Of PointType;
 Begin
  If X>SCR_W-12 Then X:=SCR_W-12;
  If Y>SCR_H-18 Then Y:=SCR_H-18;
  If X<0 Then X:=0;
  If Y<0 Then Y:=0;
  CursorErase;
  CurSz:=ImageSize(X,Y,X+11,Y+17);
  GetMem(CurBuf,CurSz);
  GetImage(X,Y,X+11,Y+17,CurBuf^);
  CurX:=X;CurY:=Y;CurSaved:=True;
  Pt[1].X:=X;    Pt[1].Y:=Y;
  Pt[2].X:=X;    Pt[2].Y:=Y+14;
  Pt[3].X:=X+4;  Pt[3].Y:=Y+11;
  Pt[4].X:=X+7;  Pt[4].Y:=Y+16;
  Pt[5].X:=X+9;  Pt[5].Y:=Y+15;
  Pt[6].X:=X+6;  Pt[6].Y:=Y+10;
  Pt[7].X:=X+10; Pt[7].Y:=Y+10;
  SetFillStyle(SolidFill,Black);
  SetColor(White);
  FillPoly(7,Pt);
 End;

 Procedure ShowMouse;
 Begin
  CurShown:=True;
  CursorDraw(MX,MY);
 End;

 Procedure HideMouse;
 Begin
  CursorErase;
  CurShown:=False;
 End;
{$ENDIF}

{ ====================================================================== }
{                       PRIMITIVES GRAPHIQUES                            }
{ ====================================================================== }

Const
 PatChecker : FillPatternType = ($AA,$55,$AA,$55,$AA,$55,$AA,$55);
 PatLight   : FillPatternType = ($88,$22,$88,$22,$88,$22,$88,$22);
 PatDark    : FillPatternType = ($77,$DD,$77,$DD,$77,$DD,$77,$DD);
 PatHyper   : Array[0..3] Of FillPatternType = (
  ($FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF),
  ($AA,$55,$AA,$55,$AA,$55,$AA,$55),
  ($88,$44,$22,$11,$88,$44,$22,$11),
  ($77,$DD,$77,$DD,$77,$DD,$77,$DD));

Procedure Box(X1,Y1,X2,Y2,C: Integer);
Begin
 SetFillStyle(SolidFill,C);
 Bar(X1,Y1,X2,Y2);
End;

Procedure Frame(X1,Y1,X2,Y2: Integer);
Begin
 SetColor(INK);
 SetLineStyle(SolidLn,0,1);
 Rectangle(X1,Y1,X2,Y2);
End;

{ Le BGI peint les bits a 1 avec la couleur et les bits a 0 avec la couleur 0 :
  on inverse donc le motif et on le peint en blanc pour obtenir noir sur blanc }
Procedure PatBar(X1,Y1,X2,Y2: Integer; Const Pat: FillPatternType);
Var Q: FillPatternType; I: Integer;
Begin
 For I:=1 To 8 Do Q[I]:=Not Pat[I];
 SetFillPattern(Q,PAPER);
 Bar(X1,Y1,X2,Y2);
End;

Procedure PText(X,Y: Integer; Const S: String);
Begin
 SetColor(INK);
 OutTextXY(X,Y,S);
End;

Procedure BText(X,Y: Integer; Const S: String);
Begin
 SetColor(INK);
 OutTextXY(X,Y,S);
 OutTextXY(X+1,Y,S);
End;

Procedure WText(X,Y: Integer; Const S: String);
Begin
 SetColor(PAPER);
 OutTextXY(X,Y,S);
End;

Procedure GreyText(X,Y: Integer; Const S: String);
Var I,J,W: Integer;
Begin
 PText(X,Y,S);
 W:=Length(S)*8;
 For J:=0 To 7 Do
  For I:=0 To W-1 Do
   If Odd(I+J) Then
    If GetPixel(X+I,Y+J)=INK Then PutPixel(X+I,Y+J,PAPER);
End;

Function TextW(Const S: String): Integer;
Begin
 TextW:=Length(S)*8;
End;

Function InBox(X,Y,X1,Y1,X2,Y2: LongInt): Boolean;
Begin
 InBox:=(X>=X1) And (X<=X2) And (Y>=Y1) And (Y<=Y2);
End;

Procedure SmallBox(X,Y: Integer);
Begin
 Box(X,Y,X+TB_H-1,Y+TB_H-1,PAPER);
 Frame(X,Y,X+TB_H-1,Y+TB_H-1);
 Frame(X+4,Y+4,X+TB_H-5,Y+TB_H-5);
End;

Procedure ArrowBox(X1,Y1,X2,Y2,Dir: Integer);
{ Dir : 1 haut, 2 bas, 3 gauche, 4 droite }
Var Pt: Array[1..3] Of PointType; CX,CY: Integer;
Begin
 Box(X1,Y1,X2,Y2,PAPER);
 Frame(X1,Y1,X2,Y2);
 CX:=(X1+X2) Div 2;CY:=(Y1+Y2) Div 2;
 Case Dir Of
  1: Begin
    Pt[1].X:=CX;Pt[1].Y:=CY-3;Pt[2].X:=CX-4;Pt[2].Y:=CY+3;Pt[3].X:=CX+4;
    Pt[3].Y:=CY+3;End;
  2: Begin
    Pt[1].X:=CX;Pt[1].Y:=CY+3;Pt[2].X:=CX-4;Pt[2].Y:=CY-3;Pt[3].X:=CX+4;
    Pt[3].Y:=CY-3;End;
  3: Begin
    Pt[1].X:=CX-3;Pt[1].Y:=CY;Pt[2].X:=CX+3;Pt[2].Y:=CY-4;Pt[3].X:=CX+3;
    Pt[3].Y:=CY+4;End;
  4: Begin
    Pt[1].X:=CX+3;Pt[1].Y:=CY;Pt[2].X:=CX-3;Pt[2].Y:=CY-4;Pt[3].X:=CX-3;
    Pt[3].Y:=CY+4;End;
 End;
 SetFillStyle(SolidFill,INK);
 SetColor(INK);
 FillPoly(3,Pt);
End;

Procedure Button(X1,Y1,X2,Y2: Integer; Const S: String; Hot,Enabled: Boolean);
Var TX: Integer;
Begin
 If Hot Then Begin
  Box(X1,Y1,X2,Y2,INK);
  Frame(X1-1,Y1-1,X2+1,Y2+1);
 End Else Begin
  Box(X1,Y1,X2,Y2,PAPER);
  Frame(X1,Y1,X2,Y2);
 End;
 TX:=(X1+X2+1-TextW(S)) Div 2;
 If Not Enabled Then GreyText(TX,(Y1+Y2-6) Div 2,S)
 Else If Hot Then WText(TX,(Y1+Y2-6) Div 2,S)
 Else PText(TX,(Y1+Y2-6) Div 2,S);
End;

Procedure DlgBox(X1,Y1,X2,Y2: Integer; Const Title: String; OkBox: Boolean);
Begin
 Box(X1+4,Y1+4,X2+4,Y2+4,INK);
 Box(X1,Y1,X2,Y2,PAPER);
 Frame(X1,Y1,X2,Y2);
 Frame(X1+1,Y1+1,X2-1,Y2-1);
 Box(X1+2,Y1+2,X2-2,Y1+TB_H,PAPER);
 SetColor(INK);
 Line(X1+1,Y1+TB_H+1,X2-1,Y1+TB_H+1);
 SmallBox(X1+2,Y1+2);
 BText((X1+X2-TextW(Title)) Div 2,Y1+6,Title);
 If OkBox Then Begin
  Frame(X2-30,Y1+3,X2-4,Y1+TB_H);
  PText(X2-26,Y1+7,'OK');
 End;
End;

{ ====================================================================== }
Var
 NeedDraw : Boolean;
 Quit     : Boolean;

Procedure DrawAll; Forward;
Procedure EngineStep; Forward;

Procedure PollEvent(Var E: TEvent);
Var Ch: Char; K: Word;
Begin
 E.Kind:=0;E.Key:=0;E.X:=MX;E.Y:=MY;E.B:=MB;
 If KeyPressed Then Begin
  Ch:=ReadKey;
  If Ch=#0 Then K:=256+Ord(ReadKey) Else K:=Ord(Ch);
  E.Kind:=1;E.Key:=K;
  Exit;
 End;
 PrevMX:=MX;PrevMY:=MY;LastB:=MB;
 GetMouseState(MX,MY,MB);
 E.X:=MX;E.Y:=MY;E.B:=MB;
 If ((MB And 3)<>0) And ((LastB And 3)=0) Then E.Kind:=2
 Else If ((MB And 3)=0) And ((LastB And 3)<>0) Then E.Kind:=3
 Else If (MX<>PrevMX) Or (MY<>PrevMY) Then E.Kind:=4;
 {$IFDEF FPC}
 If (E.Kind<>0) And CurShown And ((MX<>CurX) Or (MY<>CurY)) Then
  CursorDraw(MX,MY);
 {$ENDIF}
 If E.Kind=0 Then Begin
  EngineStep;
  {$IFDEF MSWINDOWS}
  Sleep(2);
  {$ELSE}
  Delay(3);
  {$ENDIF}
 End;
End;

{ ====================================================================== }

Var
 FormLbl : Array[1..12] Of String[30];
 FormVal : Array[1..12] Of String[70];
 FormFW  : Integer;
 LstItem : Array[1..120] Of String[36];
 LstN    : Integer;

Procedure MsgBox(Const Title,Txt: String);
Var Lines: Array[1..14] Of
  String[60]; N,I,W,X1,Y1,X2,Y2,P: Integer; S: String; E: TEvent;
  Done: Boolean;
Begin
 N:=0;S:=Txt;
 While (S<>'') And (N<14) Do Begin
  P:=Pos('|',S);
  Inc(N);
  If P=0 Then Begin Lines[N]:=Copy(S,1,60);S:='';End
  Else Begin Lines[N]:=Copy(S,1,P-1);Delete(S,1,P);End;
 End;
 W:=TextW(Title)+80;
 For I:=1 To N Do If TextW(Lines[I])+32>W Then W:=TextW(Lines[I])+32;
 If W<200 Then W:=200;
 X1:=(SCR_W-W) Div 2;X2:=X1+W;
 Y1:=(SCR_H-(N*12+TB_H+40)) Div 2;Y2:=Y1+N*12+TB_H+40;
 HideMouse;
 DlgBox(X1,Y1,X2,Y2,Title,True);
 For I:=1 To N Do PText(X1+16,Y1+TB_H+14+(I-1)*12,Lines[I]);
 Button((X1+X2) Div 2-30,Y2-26,(X1+X2) Div 2+30,Y2-8,'OK',True,True);
 ShowMouse;
 Done:=False;
 Repeat
  PollEvent(E);
  If E.Kind=1 Then Begin
   If (E.Key=K_ENTER) Or (E.Key=K_ESC) Or (E.Key=32) Then Done:=True;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X1+2,Y1+2,X1+TB_H+2,Y1+TB_H+2)
       Or InBox(E.X,E.Y,X2-30,Y1+3,X2-4,Y1+TB_H)
      Or InBox(E.X,E.Y,(X1+X2) Div 2-30,Y2-26,(X1+X2) Div 2+30,Y2-8) Then
        Done:=True;
  End;
 Until Done;
 NeedDraw:=True;
End;

Function ConfirmBox(Const Txt: String): Boolean;
Var X1,Y1,X2,Y2,W: Integer; E: TEvent; Done: Boolean; YesS,NoS: String;
Begin
 YesS:=T3('Yes','Oui','Ja');NoS:=T3('No','Non','Nein');
 W:=TextW(Txt)+40;
 If W<280 Then W:=280;
 X1:=(SCR_W-W) Div 2;X2:=X1+W;Y1:=190;Y2:=Y1+90;
 HideMouse;
 DlgBox(X1,Y1,X2,Y2,'CUBASE',False);
 PText(X1+20,Y1+TB_H+14,Txt);
 Button(X1+20,Y2-30,X1+90,Y2-10,YesS,True,True);
 Button(X2-90,Y2-30,X2-20,Y2-10,NoS,False,True);
 ShowMouse;
 Done:=False;ConfirmBox:=False;
 Repeat
  PollEvent(E);
  If E.Kind=1 Then Begin
   If (UpCase(Chr(E.Key And $FF))=YesS[1]) Or (E.Key=K_ENTER) Then Begin
     ConfirmBox:=True;Done:=True;End;
   If (UpCase(Chr(E.Key And $FF))=NoS[1]) Or (E.Key=K_ESC) Then Begin
     ConfirmBox:=False;Done:=True;End;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X1+20,Y2-30,X1+90,Y2-10) Then Begin
     ConfirmBox:=True;Done:=True;End;
   If InBox(E.X,E.Y,X2-90,Y2-30,X2-20,Y2-10) Then Done:=True;
  End;
 Until Done;
 NeedDraw:=True;
End;

Function FormBox(Const Title: String; N: Integer): Boolean;
Var LW,W,H,X1,Y1,X2,Y2,I,F,FX,FY,FW: Integer; E: TEvent;
Done,Ok,Fresh,Redraw: Boolean; Ch: Char; CancelS: String;
Begin
 CancelS:=T3('Cancel','Annuler','Abbruch');
 LW:=0;
 For I:=1 To N Do If Length(FormLbl[I])>LW Then LW:=Length(FormLbl[I]);
 LW:=LW*8+8;
 FW:=FormFW*8+8;
 W:=LW+FW+32;
 If W<TextW(Title)+80 Then W:=TextW(Title)+80;
 If W>620 Then Begin W:=620;FW:=W-LW-32;End;
 H:=TB_H+N*22+56;
 X1:=(SCR_W-W) Div 2;X2:=X1+W;Y1:=(SCR_H-H) Div 2-20;Y2:=Y1+H;
 F:=1;Fresh:=True;Done:=False;Ok:=False;Redraw:=True;
 Repeat
  If Redraw Then Begin
   HideMouse;
   DlgBox(X1,Y1,X2,Y2,Title,True);
   For I:=1 To N Do Begin
    PText(X1+14,Y1+TB_H+16+(I-1)*22,FormLbl[I]);
    FX:=X1+14+LW;FY:=Y1+TB_H+12+(I-1)*22;
    Box(FX,FY,FX+FW,FY+14,PAPER);
    Frame(FX,FY,FX+FW,FY+14);
    If (I=F) And Fresh Then Begin
     Box(FX+1,FY+1,FX+8*Length(FormVal[I])+3,FY+13,INK);
     WText(FX+3,FY+4,Copy(FormVal[I],1,FormFW));
    End Else Begin
     PText(FX+3,FY+4,Copy(FormVal[I],1,FormFW));
     If I=F Then PText(FX+3+8*Length(Copy(FormVal[I],1,FormFW)),FY+4,'_');
    End;
   End;
   Button(X1+14,Y2-28,X1+84,Y2-8,'OK',True,True);
   Button(X2-94,Y2-28,X2-14,Y2-8,CancelS,False,True);
   ShowMouse;
   Redraw:=False;
  End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   Case E.Key Of
    K_ENTER: Begin Ok:=True;Done:=True;End;
    K_ESC: Done:=True;
    K_TAB,K_DOWN: Begin If F<N Then Inc(F) Else
      F:=1;Fresh:=True;Redraw:=True;End;
    K_STAB,K_UP: Begin If F>1 Then Dec(F) Else
      F:=N;Fresh:=True;Redraw:=True;End;
    K_BKSP: Begin
             If Fresh Then FormVal[F]:='' Else If Length(FormVal[F])>0 Then
               Dec(FormVal[F][0]);
             Fresh:=False;Redraw:=True;
            End;
    K_DEL: Begin FormVal[F]:='';Fresh:=False;Redraw:=True;End;
    32..255: Begin
              Ch:=Chr(E.Key);
              If Fresh Then FormVal[F]:='';
              Fresh:=False;
              If Length(FormVal[F])<FormFW Then FormVal[F]:=FormVal[F]+Ch;
              Redraw:=True;
             End;
   End;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X1+2,Y1+2,X1+TB_H+2,Y1+TB_H+2) Then Done:=True
   Else
     If InBox(E.X,E.Y,X2-30,Y1+3,X2-4,Y1+TB_H)
       Or InBox(E.X,E.Y,X1+14,Y2-28,X1+84,Y2-8) Then Begin
     Ok:=True;Done:=True;End
   Else If InBox(E.X,E.Y,X2-94,Y2-28,X2-14,Y2-8) Then Done:=True
   Else For I:=1 To N Do
    If InBox(E.X,E.Y,X1+14+LW,Y1+TB_H+12+(I-1)*22,X1+14+LW+FW,
        Y1+TB_H+26+(I-1)*22) Then Begin
     F:=I;Fresh:=False;Redraw:=True;
    End;
  End;
 Until Done;
 FormBox:=Ok;
 NeedDraw:=True;
End;

Function InputBox(Const Title,Prompt: String; Var S: String;
                  MaxLen: Integer): Boolean;
Begin
 FormLbl[1]:=Copy(Prompt,1,30);
 FormVal[1]:=Copy(S,1,70);
 FormFW:=MaxLen;
 If FormFW>40 Then FormFW:=40;
 If FormBox(Title,1) Then Begin
  S:=FormVal[1];
  InputBox:=True;
 End Else InputBox:=False;
End;

{ Demande un nombre ; retourne False si annule }
Function AskNum(Const Title,Prompt: String; Var V: LongInt;
                Lo,Hi: LongInt): Boolean;
Var S: String;
Begin
 AskNum:=False;
 S:=IntStr(V);
 If InputBox(Title,Prompt,S,10) Then Begin
  V:=Clamp(ToInt(S),Lo,Hi);
  AskNum:=True;
 End;
End;

{ Boite de selection dans une liste : LstItem[1..LstN]. Retourne 0 si annule }
Function ChooseBox(Const Title: String; Start: Integer): Integer;
Var X1,Y1,X2,Y2,W,H,I,Top,Sel,VisN: Integer; E: TEvent; Done,Redraw: Boolean;
Res: Integer; CancelS: String;
Begin
 CancelS:=T3('Cancel','Annuler','Abbruch');
 W:=TextW(Title)+80;
 For I:=1 To LstN Do If TextW(LstItem[I])+60>W Then W:=TextW(LstItem[I])+60;
 If W<260 Then W:=260;
 VisN:=LstN;
 If VisN>16 Then VisN:=16;
 If VisN<3 Then VisN:=3;
 H:=TB_H+VisN*12+50;
 X1:=(SCR_W-W) Div 2;X2:=X1+W;Y1:=(SCR_H-H) Div 2-10;Y2:=Y1+H;
 Sel:=Start;If Sel<1 Then Sel:=1;If Sel>LstN Then Sel:=LstN;
 Top:=1;
 Done:=False;Res:=0;Redraw:=True;
 Repeat
  If Sel<Top Then Top:=Sel;
  If Sel>=Top+VisN Then Top:=Sel-VisN+1;
  If Redraw Then Begin
   HideMouse;
   DlgBox(X1,Y1,X2,Y2,Title,True);
   Box(X1+10,Y1+TB_H+8,X2-28,Y1+TB_H+8+VisN*12+2,PAPER);
   Frame(X1+10,Y1+TB_H+8,X2-28,Y1+TB_H+8+VisN*12+2);
   For I:=Top To Top+VisN-1 Do
    If I<=LstN Then Begin
     If I=Sel Then Begin
      Box(X1+11,Y1+TB_H+9+(I-Top)*12,X2-29,Y1+TB_H+20+(I-Top)*12,INK);
      WText(X1+14,Y1+TB_H+11+(I-Top)*12,LstItem[I]);
     End Else PText(X1+14,Y1+TB_H+11+(I-Top)*12,LstItem[I]);
    End;
   ArrowBox(X2-26,Y1+TB_H+8,X2-10,Y1+TB_H+24,1);
   ArrowBox(X2-26,Y1+TB_H+8+VisN*12-14,X2-10,Y1+TB_H+8+VisN*12+2,2);
   Button(X1+14,Y2-26,X1+84,Y2-8,'OK',True,True);
   Button(X2-94,Y2-26,X2-14,Y2-8,CancelS,False,True);
   ShowMouse;
   Redraw:=False;
  End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   Case E.Key Of
    K_ENTER: Begin Res:=Sel;Done:=True;End;
    K_ESC: Done:=True;
    K_UP: If Sel>1 Then Begin Dec(Sel);Redraw:=True;End;
    K_DOWN: If Sel<LstN Then Begin Inc(Sel);Redraw:=True;End;
    K_PGUP: Begin Sel:=Max2(1,Sel-VisN);Redraw:=True;End;
    K_PGDN: Begin Sel:=Min2(LstN,Sel+VisN);Redraw:=True;End;
    K_HOME: Begin Sel:=1;Redraw:=True;End;
    K_END: Begin Sel:=LstN;Redraw:=True;End;
   End;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X1+2,Y1+2,X1+TB_H+2,Y1+TB_H+2)
       Or InBox(E.X,E.Y,X2-94,Y2-26,X2-14,Y2-8) Then Done:=True
   Else
     If InBox(E.X,E.Y,X2-30,Y1+3,X2-4,Y1+TB_H)
       Or InBox(E.X,E.Y,X1+14,Y2-26,X1+84,Y2-8) Then Begin
     Res:=Sel;Done:=True;End
   Else If InBox(E.X,E.Y,X2-26,Y1+TB_H+8,X2-10,Y1+TB_H+24) Then Begin
     If Sel>1 Then Dec(Sel);Redraw:=True;End
   Else
     If InBox(E.X,E.Y,X2-26,Y1+TB_H+8+VisN*12-14,X2-10,Y1+TB_H+8+VisN*12+2) Then
     Begin If Sel<LstN Then Inc(Sel);Redraw:=True;End
   Else If InBox(E.X,E.Y,X1+10,Y1+TB_H+8,X2-28,Y1+TB_H+8+VisN*12) Then Begin
    I:=Top+((E.Y-(Y1+TB_H+9)) Div 12);
    If (I>=1) And (I<=LstN) Then Begin
     If I=Sel Then Begin Res:=Sel;Done:=True;End;
     Sel:=I;Redraw:=True;
    End;
   End;
  End;
 Until Done;
 ChooseBox:=Res;
 NeedDraw:=True;
End;

{ Selecteur de fichier : liste les fichiers correspondant au masque }
Procedure ScanFiles(Const Mask: String);
Var SR: SearchRec; I: Integer; Dup: Boolean;
Begin
 FindFirst(Mask,AnyFile-Directory,SR);
 While (DosError=0) And (LstN<119) Do Begin
  Dup:=False;
  For I:=1 To LstN Do If LstItem[I]=Copy(SR.Name,1,36) Then Dup:=True;
  If Not Dup Then Begin
   Inc(LstN);
   LstItem[LstN]:=Copy(SR.Name,1,36);
  End;
  FindNext(SR);
 End;
 {$IFDEF FPC}
 FindClose(SR);
 {$ENDIF}
End;

Function LowerStr(S: String): String;
Var I: Integer;
Begin
 For I:=1 To Length(S) Do
  If (S[I]>='A') And (S[I]<='Z') Then S[I]:=Chr(Ord(S[I])+32);
 LowerStr:=S;
End;

Function FileSelect(Const Title,Mask: String; Var Name: String): Boolean;
Var I,Sel: Integer; S: String;
Begin
 LstN:=0;
 ScanFiles(Mask);
 If LowerStr(Mask)<>Mask Then ScanFiles(LowerStr(Mask));
 Inc(LstN);
 LstItem[LstN]:=T3('[ Type a name... ]','[ Saisir un nom... ]',
                   '[ Namen eingeben... ]');
 FileSelect:=False;
 S:=Name;
 Sel:=1;
 For I:=1 To LstN-1 Do If Upper(LstItem[I])=Upper(ShortName(S)) Then Sel:=I;
 I:=ChooseBox(Title+' ('+Mask+')',Sel);
 If I=0 Then Exit;
 If I<LstN Then Begin
  Name:=LstItem[I];
  FileSelect:=True;
 End Else Begin
  If InputBox(Title,T3('File name','Nom du fichier','Dateiname'),S,36) Then Begin
   Name:=S;
   FileSelect:=(S<>'');
  End;
 End;
End;

{ ====================================================================== }
{                  OPTIONS DE DIALOGUE A CHOIX MULTIPLES                 }
{ ====================================================================== }

Var
 OLbl : Array[1..12] Of String[24];
 OOpt : Array[1..12] Of String[60];   { 'A|B|C' ou '#lo..hi' }
 OVal : Array[1..12] Of Integer;

Function OptText(I: Integer): String;
Var S: String; K,N,P: Integer;
Begin
 S:=OOpt[I];
 If (S<>'') And (S[1]='#') Then Begin
  OptText:=IntStr(OVal[I]);
  Exit;
 End;
 N:=OVal[I];
 K:=0;
 While (K<N) And (S<>'') Do Begin
  P:=Pos('|',S);
  If P=0 Then S:='' Else Delete(S,1,P);
  Inc(K);
 End;
 P:=Pos('|',S);
 If P>0 Then S:=Copy(S,1,P-1);
 OptText:=S;
End;

Function OptCount(I: Integer): Integer;
Var S: String; N,P: Integer;
Begin
 S:=OOpt[I];N:=1;
 P:=Pos('|',S);
 While P>0 Do Begin Inc(N);Delete(S,1,P);P:=Pos('|',S);End;
 OptCount:=N;
End;

Procedure OptRange(I: Integer; Var Lo,Hi: LongInt);
Var S: String; P,C: Integer;
Begin
 S:=Copy(OOpt[I],2,40);
 P:=Pos('..',S);
 Val(Copy(S,1,P-1),Lo,C);
 Val(Copy(S,P+2,20),Hi,C);
End;

{ Boite d'options : cliquer sur une ligne change sa valeur }
Function OptBox(Const Title: String; N: Integer): Boolean;
Var LW2,W,H,X1,Y1,X2,Y2,I: Integer; E: TEvent; Done,Ok,Redraw: Boolean;
 CancelS: String; V,Lo,Hi: LongInt; Sel: Integer;
Begin
 CancelS:=T3('Cancel','Annuler','Abbruch');
 LW2:=0;
 For I:=1 To N Do If Length(OLbl[I])>LW2 Then LW2:=Length(OLbl[I]);
 W:=LW2*8+8*12+40;
 If W<TextW(Title)+80 Then W:=TextW(Title)+80;
 H:=TB_H+N*20+56;
 X1:=(SCR_W-W) Div 2;X2:=X1+W;Y1:=(SCR_H-H) Div 2-20;Y2:=Y1+H;
 Done:=False;Ok:=False;Redraw:=True;Sel:=1;
 Repeat
  If Redraw Then Begin
   HideMouse;
   DlgBox(X1,Y1,X2,Y2,Title,True);
   For I:=1 To N Do Begin
    If I=Sel Then PText(X1+8,Y1+TB_H+17+(I-1)*20,#16);
    PText(X1+18,Y1+TB_H+17+(I-1)*20,OLbl[I]);
    Box(X2-8*12-14,Y1+TB_H+12+(I-1)*20,X2-14,Y1+TB_H+26+(I-1)*20,PAPER);
    Frame(X2-8*12-14,Y1+TB_H+12+(I-1)*20,X2-14,Y1+TB_H+26+(I-1)*20);
    BText(X2-8*12-10,Y1+TB_H+16+(I-1)*20,Copy(OptText(I),1,11));
   End;
   Button(X1+14,Y2-28,X1+84,Y2-8,'OK',True,True);
   Button(X2-94,Y2-28,X2-14,Y2-8,CancelS,False,True);
   ShowMouse;
   Redraw:=False;
  End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   Case E.Key Of
    K_ENTER: Begin Ok:=True;Done:=True;End;
    K_ESC: Done:=True;
    K_UP: Begin If Sel>1 Then Dec(Sel) Else Sel:=N;Redraw:=True;End;
    K_DOWN,K_TAB: Begin If Sel<N Then Inc(Sel) Else Sel:=1;Redraw:=True;End;
    K_LEFT,K_RIGHT,32: Begin
      If (OOpt[Sel]<>'') And (OOpt[Sel][1]='#') Then Begin
       OptRange(Sel,Lo,Hi);
       If E.Key=K_LEFT Then V:=OVal[Sel]-1 Else V:=OVal[Sel]+1;
       OVal[Sel]:=Integer(Clamp(V,Lo,Hi));
      End Else Begin
       If E.Key=K_LEFT Then Begin
        Dec(OVal[Sel]);If OVal[Sel]<0 Then OVal[Sel]:=OptCount(Sel)-1;
       End Else Begin
        Inc(OVal[Sel]);If OVal[Sel]>=OptCount(Sel) Then OVal[Sel]:=0;
       End;
      End;
      Redraw:=True;
     End;
   End;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X1+2,Y1+2,X1+TB_H+2,Y1+TB_H+2) Then Done:=True
   Else If InBox(E.X,E.Y,X2-30,Y1+3,X2-4,Y1+TB_H)
       Or InBox(E.X,E.Y,X1+14,Y2-28,X1+84,Y2-8) Then Begin
     Ok:=True;Done:=True;End
   Else If InBox(E.X,E.Y,X2-94,Y2-28,X2-14,Y2-8) Then Done:=True
   Else For I:=1 To N Do
    If InBox(E.X,E.Y,X1+8,Y1+TB_H+10+(I-1)*20,X2-10,Y1+TB_H+28+(I-1)*20) Then Begin
     Sel:=I;
     If (OOpt[I]<>'') And (OOpt[I][1]='#') Then Begin
      OptRange(I,Lo,Hi);
      V:=OVal[I];
      If AskNum(Title,OLbl[I]+' '+IntStr(Lo)+'..'+IntStr(Hi),V,Lo,Hi) Then
        OVal[I]:=Integer(V);
     End Else Begin
      Inc(OVal[I]);If OVal[I]>=OptCount(I) Then OVal[I]:=0;
     End;
     Redraw:=True;
    End;
  End;
 Until Done;
 OptBox:=Ok;
 NeedDraw:=True;
End;

{ ====================================================================== }
{                       DONNEES DE L'ARRANGEMENT                         }
{ ====================================================================== }

Const
 QuaLbl : Array[0..NQUA] Of String[4] =
  ('OFF','4','8','16','32','64','128','8T','16T','32T','64T');
 QuaTk  : Array[0..NQUA] Of Integer = (1,192,96,48,24,12,6,64,32,16,8);
 SnapLbl : Array[0..NSNAP-1] Of String[6] =
  ('OFF','BAR','BEAT','1/8','1/16','QUANT');
 ToolLbl : Array[1..NTOOL] Of String[8] =
  ('ARROW','PENCIL','ERASER','SCISSORS','GLUE','MUTE');
 EdToolLbl : Array[1..4] Of String[8] =
  ('ARROW','PENCIL','ERASER','SPEAKER');
 BarPxTab : Array[1..6] Of Integer = (10,16,24,36,56,88);
 EdPxTab  : Array[1..6] Of Integer = (12,20,32,48,72,112);
 InstName : Array[1..NINST] Of String[10] =
  ('Piano','E.Piano','Marimba','Vibes','Organ','Guitar','Bass','Slap Bass',
   'Violin','Strings','Choir','Brass','Flute','Synth','Pad','Drums');
 InstProg : Array[1..NINST] Of Byte =
  (0,4,12,11,16,25,33,36,40,48,52,61,73,80,88,0);
 CtlLbl : Array[0..7] Of String[10] =
  ('VELOCITY','PITCHBEND','MODULATION','VOLUME','PAN','EXPRESSION',
   'AFTERTOUCH','SUSTAIN');
 CtlNum : Array[0..7] Of Byte = (0,0,1,7,10,11,0,64);
 CycLbl : Array[0..2] Of String[9] = ('MIX','OVERWRITE','STACK');
 OutLbl : Array[0..2] Of String[6] = ('Atari','MIDI 1','MIDI 2');
 NoteNm : Array[0..11] Of String[2] =
  ('C ','C#','D ','D#','E ','F ','F#','G ','G#','A ','A#','B ');
 FiltName : Array[0..5] Of String[14] =
  ('NOTE ON','POLY PRESSURE','CONTROLLER','PROGRAM CHANGE','AFTER TOUCH',
   'PITCH BEND');
 FiltKind : Array[0..5] Of Byte =
  (EK_NOTE,EK_POLYP,EK_CTRL,EK_PROG,EK_CHANP,EK_BEND);

Var
 Trk      : Array[1..NTRK] Of TTrack;
 Parts    : Array[1..MAXPART] Of TPart;
 ArrPP    : TPlayPar;
 Tempos   : Array[1..NTEMPO] Of TTempoEv;
 NTemp    : Integer;
 TempoFix : Integer;                 { tempo x 10 }
 SigN,SigD: Integer;
 SongName : String[79];
 SongNamed,Modified : Boolean;
 LocL,LocR: LongInt;
 PosTick  : LongInt;
 EvUsed   : LongInt;
 View     : Integer;
 CurTrk,ArrTop : Integer;
 ViewBar  : LongInt;
 ZoomI,SnapI,QuaI,ToolI,CycMode,EdToolI : Integer;
 DrumNote : Array[1..NDRUM] Of Byte;
 DrumNm   : Array[1..NDRUM] Of String[8];
 { drapeaux et options }
 FlCycle,FlPunch,FlClick,FlMaster,FlOverdub,FlSolo,FlEdSolo : Boolean;
 FlChase,FlFollow,FlReset,FlTempoRec,FlThru : Boolean;
 SyncMode,SyncDel,CountIn,AutoQ,ClickMode : Integer;
 ClkHi,ClkLo,ClkVel,ClkChan : Integer;
 HumVel,HumLen,MidiInChan : Integer;
 RemOn,RemStart,RemStop : Integer;
 OutDev,MpuPort : Integer;
 DefVel,Oct : Integer;
 PrnDest : String[40];
 { processeur MIDI }
 MpOn : Boolean;
 MpRep,MpEcho,MpQuant,MpEDec,MpVDec,MpNDec,MpChan,MpOut : Integer;
 { editeurs }
 EdPart   : Integer;
 EdBakEv  : PEvArr;
 EdBakCnt : Integer;
 EdBakStart,EdBakStop : LongInt;
 EdT0     : LongInt;
 EdZoom   : Integer;
 EdTop    : Integer;
 CtlKind  : Integer;
 ListTop,ListSel : Integer;
 DrumVelI : Integer;
 DrumVel  : Array[1..4] Of Integer;
 MstSel,MstTop : Integer;
 UndoValid : Boolean;
 ClipN    : Integer;
 ClipP    : Array[1..24] Of TPart;
 ClipTrk0 : Integer;
 ClipT0   : LongInt;

Function MemFree: LongInt;
Var L: LongInt;
Begin
 {$IFDEF FPC}
 L:=GetFPCHeapStatus.CurrHeapFree;
 {$ELSE}
 L:=MemAvail;
 {$ENDIF}
 If L<0 Then L:=0;
 MemFree:=L;
End;

{ ---- temps ---- }

Function FloorDiv(A,B: LongInt): LongInt;
Begin
 If A>=0 Then FloorDiv:=A Div B
 Else FloorDiv:=-((-A+B-1) Div B);
End;

Function BeatTicks: LongInt;
Begin
 BeatTicks:=(4*PPQ) Div SigD;
End;

Function BarTicks: LongInt;
Begin
 BarTicks:=BeatTicks*SigN;
End;

Function QuaTick: LongInt;
Begin
 QuaTick:=QuaTk[QuaI];
End;

Function SnapTk: LongInt;
Begin
 Case SnapI Of
  1: SnapTk:=BarTicks;
  2: SnapTk:=BeatTicks;
  3: SnapTk:=PPQ Div 2;
  4: SnapTk:=PPQ Div 4;
  5: SnapTk:=QuaTk[QuaI];
 Else SnapTk:=1;
 End;
End;

Function Quant(T,Q: LongInt): LongInt;
Begin
 If Q<=1 Then Quant:=T
 Else Quant:=FloorDiv(T+Q Div 2,Q)*Q;
End;

Function SnapT(T: LongInt): LongInt;
Begin
 SnapT:=Quant(T,SnapTk);
End;

Procedure TickToBBT(T: LongInt; Var Bar,Beat,Tk: LongInt);
Var B,R: LongInt;
Begin
 B:=FloorDiv(T,BarTicks);
 R:=T-B*BarTicks;
 Bar:=B+1;
 Beat:=R Div BeatTicks+1;
 Tk:=R Mod BeatTicks;
End;

Function BBTToTick(Bar,Beat,Tk: LongInt): LongInt;
Begin
 BBTToTick:=(Bar-1)*BarTicks+(Beat-1)*BeatTicks+Tk;
End;

Function PosStr(T: LongInt): String;
Var B,Bt,Tk: LongInt;
Begin
 TickToBBT(T,B,Bt,Tk);
 PosStr:=PadL(IntStr(B),3)+'.'+PadL(IntStr(Bt),2)+'.'+PadL(IntStr(Tk),3);
End;

{ Lecture d'une position "mesure.temps.tick" (les champs absents valent 1/1/0) }
Function ParsePos(Const S: String; Var T: LongInt): Boolean;
Var N: Array[1..3] Of LongInt; K,I,C: Integer; Cur: String; V: LongInt;
Begin
 ParsePos:=False;
 N[1]:=1;N[2]:=1;N[3]:=0;
 K:=1;Cur:='';
 For I:=1 To Length(S)+1 Do Begin
  If (I>Length(S)) Or (S[I]='.') Or (S[I]=' ') Or (S[I]=',') Then Begin
   If Cur<>'' Then Begin
    Val(Cur,V,C);
    If C<>0 Then Exit;
    If K<=3 Then N[K]:=V;
    Inc(K);Cur:='';
   End;
  End Else Cur:=Cur+S[I];
 End;
 If K=1 Then Exit;
 If N[1]<1 Then N[1]:=1;
 If N[2]<1 Then N[2]:=1;
 T:=BBTToTick(N[1],N[2],N[3]);
 ParsePos:=True;
End;

Function NoteName(N: Integer): String;
Begin
 If (N<0) Or (N>127) Then Begin NoteName:='?';Exit;End;
 If NoteNm[N Mod 12][2]=' ' Then NoteName:=NoteNm[N Mod 12][1]+IntStr(N Div 12-2)
 Else NoteName:=NoteNm[N Mod 12]+IntStr(N Div 12-2);
End;

{ nom de note (C3, F#2...) ou nombre }
Function ParseNote(Const S: String; Var N: Integer): Boolean;
Var U: String; I,K,Oc,C: Integer; V: LongInt;
Begin
 ParseNote:=False;
 U:=Upper(S);
 If U='' Then Exit;
 If (U[1]>='0') And (U[1]<='9') Then Begin
  Val(U,V,C);
  If C<>0 Then Exit;
  N:=Integer(Clamp(V,0,127));
  ParseNote:=True;
  Exit;
 End;
 Case U[1] Of
  'C': K:=0; 'D': K:=2; 'E': K:=4; 'F': K:=5; 'G': K:=7; 'A': K:=9; 'B': K:=11;
 Else Exit;
 End;
 I:=2;
 If (I<=Length(U)) And ((U[I]='#') Or (U[I]='+')) Then Begin Inc(K);Inc(I);End
 Else If (I<=Length(U)) And (U[I]='B') And (I<Length(U)) Then Begin Dec(K);Inc(I);End;
 Val(Copy(U,I,5),V,C);
 If C<>0 Then Exit;
 Oc:=Integer(V);
 N:=Integer(Clamp((Oc+2)*12+K,0,127));
 ParseNote:=True;
End;

{ ---- tempo ---- }

Function TempoAt(T: LongInt): Integer;
Var I: Integer;
Begin
 If (Not FlMaster) Or (NTemp=0) Then Begin TempoAt:=TempoFix;Exit;End;
 I:=1;
 While (I<NTemp) And (Tempos[I+1].T<=T) Do Inc(I);
 TempoAt:=Tempos[I].V;
End;

Function TickMs(T: LongInt): LongInt;
Var I: Integer; Ms: Real; A,B: LongInt;
Begin
 If T<=0 Then Begin TickMs:=0;Exit;End;
 If (Not FlMaster) Or (NTemp=0) Then Begin
  TickMs:=Round(T*600000.0/(LongInt(TempoFix)*PPQ));
  Exit;
 End;
 Ms:=0;
 For I:=1 To NTemp Do Begin
  A:=Tempos[I].T;
  If I<NTemp Then B:=Tempos[I+1].T Else B:=T;
  If B>T Then B:=T;
  If A<T Then Ms:=Ms+(B-A)*600000.0/(LongInt(Tempos[I].V)*PPQ);
 End;
 TickMs:=Round(Ms);
End;

Procedure TempoSet(T: LongInt; V: Integer);
Var I: Integer;
Begin
 If V<20 Then V:=20;
 If V>3000 Then V:=3000;
 For I:=1 To NTemp Do
  If Tempos[I].T=T Then Begin Tempos[I].V:=V;Exit;End;
 If NTemp>=NTEMPO Then Exit;
 I:=NTemp;
 While (I>=1) And (Tempos[I].T>T) Do Begin Tempos[I+1]:=Tempos[I];Dec(I);End;
 Tempos[I+1].T:=T;Tempos[I+1].V:=V;
 Inc(NTemp);
End;

Procedure TempoDel(I: Integer);
Var K: Integer;
Begin
 If (I<1) Or (I>NTemp) Or (I=1) Then Exit;
 For K:=I To NTemp-1 Do Tempos[K]:=Tempos[K+1];
 Dec(NTemp);
End;

Function TempoStr(V: Integer): String;
Begin
 TempoStr:=IntStr(V Div 10)+'.'+IntStr(V Mod 10);
End;

{ ---- pistes ---- }

Procedure ResetPP(Var P: TPlayPar);
Begin
 P.Trans:=0;P.Vel:=0;P.Dly:=0;P.LenP:=100;P.Comp:=0;P.Prg:=-1;P.Vol:=-1;
End;

Procedure ResetTrack(I: Integer);
Begin
 FillChar(Trk[I],SizeOf(TTrack),0);
 Trk[I].Name:='Track '+IntStr(I);
 Trk[I].Instr:='';
 Trk[I].Chan:=((I-1) Mod 16)+1;
 Trk[I].Outp:=0;
 Trk[I].Drum:=(Trk[I].Chan=10);
 If Trk[I].Drum Then Trk[I].Instr:='Drums';
 ResetPP(Trk[I].PP);
End;

Function TimbreOf(Const S: String): Byte;
Var U: String;
Begin
 U:=Upper(S);
 TimbreOf:=0;
 If Pos('FLUTE',U)>0 Then TimbreOf:=1
 Else If (Pos('STRING',U)>0) Or (Pos('VIOLIN',U)>0) Or (Pos('ORGAN',U)>0) Or
   (Pos('PAD',U)>0) Or (Pos('SYNTH',U)>0) Or (Pos('CHOIR',U)>0) Then TimbreOf:=2
 Else If Pos('BASS',U)>0 Then TimbreOf:=3
 Else If Pos('BRASS',U)>0 Then TimbreOf:=4;
End;

Function ProgOf(Const S: String): Integer;
Var K: Integer;
Begin
 ProgOf:=-1;
 For K:=1 To NINST Do
  If Upper(InstName[K])=Upper(S) Then ProgOf:=InstProg[K];
End;

{ ---- parties ---- }

Function PartCount: Integer;
Var I,N: Integer;
Begin
 N:=0;
 For I:=1 To MAXPART Do If Parts[I].Used Then Inc(N);
 PartCount:=N;
End;

Function PartNew(Tk: Integer; St,En: LongInt; Const Nm: String): Integer;
Var I: Integer;
Begin
 PartNew:=0;
 For I:=1 To MAXPART Do
  If Not Parts[I].Used Then Begin
   FillChar(Parts[I],SizeOf(TPart),0);
   Parts[I].Used:=True;Parts[I].Trk:=Tk;Parts[I].Name:=Copy(Nm,1,12);
   Parts[I].Start:=St;Parts[I].Stop:=En;Parts[I].Cur:=1;
   ResetPP(Parts[I].PP);
   PartNew:=I;
   Exit;
  End;
End;

Procedure PartFree(I: Integer);
Begin
 If (I<1) Or (I>MAXPART) Then Exit;
 If Parts[I].Ev<>Nil Then Begin
  FreeMem(Parts[I].Ev,Parts[I].Cap*SizeOf(TEvt));
  Dec(EvUsed,Parts[I].Cnt);
 End;
 FillChar(Parts[I],SizeOf(TPart),0);
End;

Procedure PartsClear;
Var I: Integer;
Begin
 For I:=1 To MAXPART Do If Parts[I].Used Then PartFree(I);
 EvUsed:=0;
End;

Function PartGrow(P: Integer): Boolean;
Var NC: Integer; NP: PEvArr;
Begin
 PartGrow:=False;
 If Parts[P].Cap>=MAXEV Then Exit;
 NC:=Parts[P].Cap+32;
 If NC>MAXEV Then NC:=MAXEV;
 {$IFNDEF FPC}
 If MaxAvail<LongInt(NC)*SizeOf(TEvt)+4096 Then Exit;
 {$ENDIF}
 GetMem(NP,NC*SizeOf(TEvt));
 If Parts[P].Ev<>Nil Then Begin
  Move(Parts[P].Ev^,NP^,Parts[P].Cnt*SizeOf(TEvt));
  FreeMem(Parts[P].Ev,Parts[P].Cap*SizeOf(TEvt));
 End;
 Parts[P].Ev:=NP;Parts[P].Cap:=NC;
 PartGrow:=True;
End;

{ Ajoute un evenement (temps relatif au debut de la partie), liste triee }
Function EvAdd(P: Integer; T,Len: LongInt; K,D1,D2: Byte): Integer;
Var I: Integer;
Begin
 EvAdd:=0;
 If (P<1) Or (Not Parts[P].Used) Then Exit;
 If EvUsed>=POOL_EV Then Exit;
 If Parts[P].Cnt>=Parts[P].Cap Then
  If Not PartGrow(P) Then Exit;
 If T<0 Then T:=0;
 I:=Parts[P].Cnt;
 While (I>=1) And (Parts[P].Ev^[I].T>T) Do Begin
  Parts[P].Ev^[I+1]:=Parts[P].Ev^[I];Dec(I);
 End;
 Inc(I);
 Parts[P].Ev^[I].T:=T;Parts[P].Ev^[I].Len:=Len;
 Parts[P].Ev^[I].Kind:=K;Parts[P].Ev^[I].D1:=D1;Parts[P].Ev^[I].D2:=D2;
 Parts[P].Ev^[I].Sel:=False;
 Inc(Parts[P].Cnt);Inc(EvUsed);
 EvAdd:=I;
End;

Procedure EvDel(P,I: Integer);
Var K: Integer;
Begin
 If (P<1) Or (I<1) Or (I>Parts[P].Cnt) Then Exit;
 For K:=I To Parts[P].Cnt-1 Do Parts[P].Ev^[K]:=Parts[P].Ev^[K+1];
 Dec(Parts[P].Cnt);Dec(EvUsed);
End;

Procedure PartSort(P: Integer);
Var I,J: Integer; X: TEvt;
Begin
 For I:=2 To Parts[P].Cnt Do Begin
  X:=Parts[P].Ev^[I];J:=I-1;
  While (J>=1) And (Parts[P].Ev^[J].T>X.T) Do Begin
   Parts[P].Ev^[J+1]:=Parts[P].Ev^[J];Dec(J);End;
  Parts[P].Ev^[J+1]:=X;
 End;
End;

Function PartCopy(Src: Integer): Integer;
Var D,I: Integer;
Begin
 PartCopy:=0;
 D:=PartNew(Parts[Src].Trk,Parts[Src].Start,Parts[Src].Stop,Parts[Src].Name);
 If D=0 Then Exit;
 Parts[D].PP:=Parts[Src].PP;Parts[D].Mute:=Parts[Src].Mute;
 For I:=1 To Parts[Src].Cnt Do
  If EvAdd(D,Parts[Src].Ev^[I].T,Parts[Src].Ev^[I].Len,Parts[Src].Ev^[I].Kind,
     Parts[Src].Ev^[I].D1,Parts[Src].Ev^[I].D2)=0 Then Begin
   PartCopy:=D;Exit;End;
 PartCopy:=D;
End;

Function PartAt(Tk: Integer; T: LongInt): Integer;
Var I: Integer;
Begin
 PartAt:=0;
 For I:=1 To MAXPART Do
  If Parts[I].Used And (Parts[I].Trk=Tk) And (T>=Parts[I].Start) And
     (T<Parts[I].Stop) Then Begin PartAt:=I;Exit;End;
End;

Function SelPartCount: Integer;
Var I,N: Integer;
Begin
 N:=0;
 For I:=1 To MAXPART Do If Parts[I].Used And Parts[I].Sel Then Inc(N);
 SelPartCount:=N;
End;

Function FirstSelPart: Integer;
Var I: Integer;
Begin
 FirstSelPart:=0;
 For I:=1 To MAXPART Do
  If Parts[I].Used And Parts[I].Sel Then Begin FirstSelPart:=I;Exit;End;
End;

Function SongEnd: LongInt;
Var I: Integer; M: LongInt;
Begin
 M:=0;
 For I:=1 To MAXPART Do
  If Parts[I].Used And (Parts[I].Stop>M) Then M:=Parts[I].Stop;
 SongEnd:=M;
End;

Procedure InitSong;
Var I: Integer;
Begin
 PartsClear;
 For I:=1 To NTRK Do ResetTrack(I);
 ResetPP(ArrPP);
 NTemp:=0;TempoFix:=1200;SigN:=4;SigD:=4;
 LocL:=0;LocR:=BBTToTick(5,1,0);PosTick:=0;
 For I:=1 To NDRUM Do Begin DrumNote[I]:=0;End;
 DrumNote[1]:=36;DrumNm[1]:='BD 1';DrumNote[2]:=37;DrumNm[2]:='Rim';
 DrumNote[3]:=38;DrumNm[3]:='Snare 1';DrumNote[4]:=39;DrumNm[4]:='Clap';
 DrumNote[5]:=40;DrumNm[5]:='Dry SD';DrumNote[6]:=41;DrumNm[6]:='Tom 1';
 DrumNote[7]:=42;DrumNm[7]:='HH cl';DrumNote[8]:=44;DrumNm[8]:='HH ped';
 DrumNote[9]:=46;DrumNm[9]:='Open HH';DrumNote[10]:=43;DrumNm[10]:='Tom 2';
 DrumNote[11]:=45;DrumNm[11]:='Tom 3';DrumNote[12]:=47;DrumNm[12]:='Tom 4';
 DrumNote[13]:=48;DrumNm[13]:='Tom 5';DrumNote[14]:=49;DrumNm[14]:='Crash';
 DrumNote[15]:=51;DrumNm[15]:='Ride';DrumNote[16]:=56;DrumNm[16]:='Cowbell';
 SongName:='UNTITLED.ARR';SongNamed:=False;Modified:=False;
 CurTrk:=1;ArrTop:=1;ViewBar:=0;
End;

{ ====================================================================== }
{                  MOTEUR : SORTIE MIDI / LECTURE / ENREGISTREMENT       }
{ ====================================================================== }

Const
 MAXSND = 48;
 SpkBase : Array[0..11] Of Word =
  (818,866,917,972,1030,1091,1156,1224,1297,1375,1457,1544);

Type
 TSnd = Record
  Used,UseCs : Boolean;
  Port,Chan,Note : Byte;
  OffAt : LongInt;
 End;
 TPend = Record
  Used : Boolean;
  AtCs : LongInt;
  Port,Chan,Note,Vel : Byte;
 End;

Var
 Playing,Recording,CountInOn : Boolean;
 PlayTick   : LongInt;
 LastCs,RemT: LongInt;
 Snd        : Array[1..MAXSND] Of TSnd;
 Pend       : Array[1..32] Of TPend;
 SoloAny    : Boolean;
 SpkFreq    : Word;
 ClickUntil : LongInt;
 LastBeat   : LongInt;
 RecTrk     : Integer;
 RecPart    : Integer;
 RecT0      : LongInt;
 RecStart   : Array[0..127] Of LongInt;
 InSt,InD1,InN : Integer;
 PlayShown  : LongInt;
 PlayX      : Integer;

Function NowCs: LongInt;
{$IFDEF MSWINDOWS}
Begin
 NowCs:=LongInt(GetTickCount Div 10);
End;
{$ELSE}
Var H,M,S,S100: Word;
Begin
 GetTime(H,M,S,S100);
 NowCs:=((LongInt(H)*60+M)*60+S)*100+S100;
End;
{$ENDIF}

Function CurPos: LongInt;
Begin
 If Playing Then CurPos:=PlayTick Else CurPos:=PosTick;
End;

{$IFNDEF FPC}
Procedure MpuWrite(B: Byte);
Var N: Word;
Begin
 N:=0;
 While ((Port[MpuPort+1] And $40)<>0) And (N<60000) Do Inc(N);
 Port[MpuPort]:=B;
End;

Procedure MpuInit;
Var N: Word;
Begin
 N:=0;
 While ((Port[MpuPort+1] And $40)<>0) And (N<60000) Do Inc(N);
 Port[MpuPort+1]:=$3F;
 N:=0;
 While ((Port[MpuPort+1] And $80)<>0) And (N<60000) Do Inc(N);
 If (Port[MpuPort+1] And $80)=0 Then N:=Port[MpuPort];
End;
{$ENDIF}

Procedure MidiSend(Port1,St,D1,D2: Byte; Cnt: Integer);
Begin
 {$IFNDEF FPC}
 If (OutDev=1) And (Port1<=2) Then Begin
  MpuWrite(St);
  If Cnt>1 Then MpuWrite(D1);
  If Cnt>2 Then MpuWrite(D2);
 End;
 {$ENDIF}
End;

{$IFDEF MSWINDOWS}
{ ---- Synthetiseur logiciel PCM16 mono envoye a l'API waveOut ---- }
{$PUSH}{$Q-}{$R-}
Const
 SynthRate  = 22050;
 SynthBlock = 2048;          { octets par tampon (1024 echantillons) }
 NVoice     = 24;
 NSlots     = 4;

Type
 TSynthSlot = Record
  Data : Array[0..SynthBlock-1] Of Byte;
  Head : TWaveHdr;
  Prepared : Boolean;
 End;
 TVoice = Record
  Used : Boolean;
  Chan,Note,Timbre,Stage,Kind : Byte;
  Phase,Inc,IncMin,Seed : LongWord;
  Level,Amp,Age,Atk,DecS,Sus,RelS,Prev : LongInt;
 End;
 PSmallArr = ^TSmallArr;
 TSmallArr = Array[0..SynthBlock Div 2-1] Of SmallInt;

Var
 WaveHandle : HWAVEOUT;
 WaveOpened : Boolean;
 SynSlots   : Array[0..NSlots-1] Of TSynthSlot;
 Voices     : Array[1..NVoice] Of TVoice;
 SinTab     : Array[0..255] Of LongInt;
 NoteInc    : Array[0..127] Of LongWord;
 ChanTimbre : Array[1..16] Of Byte;
 VoiceAge   : LongInt;
 TablesDone : Boolean;

Procedure SynthTables;
Var I: Integer; F: Double;
Begin
 If TablesDone Then Exit;
 For I:=0 To 255 Do SinTab[I]:=Round(32767*Sin(2*Pi*I/256));
 For I:=0 To 127 Do Begin
  F:=440*Exp(Ln(2)*(I-69)/12);
  NoteInc[I]:=LongWord(Round(F/SynthRate*4294967296.0));
 End;
 For I:=1 To 16 Do ChanTimbre[I]:=0;
 FillChar(Voices,SizeOf(Voices),0);
 TablesDone:=True;
End;

Function SynthStart: Boolean;
Var Format: TWaveFormatEx; J: Integer;
Begin
 SynthStart:=False;
 If WaveOpened Then Begin SynthStart:=True;Exit;End;
 SynthTables;
 FillChar(Format,SizeOf(Format),0);
 Format.wFormatTag:=WAVE_FORMAT_PCM;
 Format.nChannels:=1;
 Format.nSamplesPerSec:=SynthRate;
 Format.wBitsPerSample:=16;
 Format.nBlockAlign:=2;
 Format.nAvgBytesPerSec:=SynthRate*2;
 If waveOutOpen(@WaveHandle,WAVE_MAPPER,@Format,0,0,CALLBACK_NULL)<>
   MMSYSERR_NOERROR Then Exit;
 WaveOpened:=True;
 For J:=0 To NSlots-1 Do Begin
  FillChar(SynSlots[J].Data,SizeOf(SynSlots[J].Data),0);
  FillChar(SynSlots[J].Head,SizeOf(TWaveHdr),0);
  SynSlots[J].Head.lpData:=@SynSlots[J].Data;
  SynSlots[J].Head.dwBufferLength:=SynthBlock;
  If waveOutPrepareHeader(WaveHandle,@SynSlots[J].Head,SizeOf(TWaveHdr))<>
    MMSYSERR_NOERROR Then SynSlots[J].Prepared:=False
  Else SynSlots[J].Prepared:=True;
 End;
 SynthStart:=True;
End;

Procedure SynthStop;
Var J: Integer;
Begin
 If Not WaveOpened Then Exit;
 waveOutReset(WaveHandle);
 For J:=0 To NSlots-1 Do
  If SynSlots[J].Prepared Then Begin
   waveOutUnprepareHeader(WaveHandle,@SynSlots[J].Head,SizeOf(TWaveHdr));
   SynSlots[J].Prepared:=False;
  End;
 waveOutClose(WaveHandle);
 WaveOpened:=False;
 FillChar(Voices,SizeOf(Voices),0);
End;

Procedure SynthNoteOn(Ch,Nt,Vl,Tb: Integer);
Var I,F,Old: Integer;
Begin
 If Not WaveOpened Then Exit;
 F:=0;Old:=1;
 For I:=1 To NVoice Do Begin
  If (F=0) And (Not Voices[I].Used) Then F:=I;
  If Voices[I].Age<Voices[Old].Age Then Old:=I;
 End;
 If F=0 Then F:=Old;
 Inc(VoiceAge);
 Voices[F].Used:=True;Voices[F].Chan:=Ch;Voices[F].Note:=Nt;
 Voices[F].Timbre:=Tb;Voices[F].Stage:=0;Voices[F].Kind:=0;
 Voices[F].Phase:=0;Voices[F].Level:=0;Voices[F].Prev:=0;
 Voices[F].Seed:=LongWord(VoiceAge)*2654435761+LongWord(Nt);
 Voices[F].Age:=VoiceAge;
 Voices[F].Amp:=Vl;
 Voices[F].Inc:=NoteInc[Clamp(Nt,0,127)];
 Voices[F].IncMin:=0;
 If Ch=10 Then Begin
  { batterie : timbre = famille de percussion }
  Voices[F].Timbre:=5;Voices[F].Stage:=1;Voices[F].Level:=32767;
  Voices[F].Atk:=0;Voices[F].Sus:=0;Voices[F].RelS:=9;
  Case Nt Of
   35,36: Begin Voices[F].Kind:=1;Voices[F].DecS:=12;
           Voices[F].Inc:=NoteInc[67];Voices[F].IncMin:=NoteInc[31];End;
   37,38,39,40: Begin Voices[F].Kind:=2;Voices[F].DecS:=11;
           Voices[F].Inc:=NoteInc[55];End;
   42,44: Begin Voices[F].Kind:=3;Voices[F].DecS:=9;End;
   46: Begin Voices[F].Kind:=3;Voices[F].DecS:=12;End;
   49,51,52,53,55,57: Begin Voices[F].Kind:=3;Voices[F].DecS:=14;End;
   41,43,45,47,48,50: Begin Voices[F].Kind:=4;Voices[F].DecS:=12;
           Voices[F].Inc:=NoteInc[Clamp(Nt+12,0,127)];
           Voices[F].IncMin:=NoteInc[Clamp(Nt+4,0,127)];End;
   56: Begin Voices[F].Kind:=5;Voices[F].DecS:=11;
           Voices[F].Inc:=NoteInc[89];End;
  Else Begin Voices[F].Kind:=2;Voices[F].DecS:=10;End;
  End;
 End Else
  Case Tb Of
   1: Begin Voices[F].Atk:=40;Voices[F].DecS:=14;Voices[F].Sus:=26000;Voices[F].RelS:=10;End;
   2: Begin Voices[F].Atk:=12;Voices[F].DecS:=14;Voices[F].Sus:=28000;Voices[F].RelS:=11;End;
   3: Begin Voices[F].Atk:=6000;Voices[F].DecS:=12;Voices[F].Sus:=6000;Voices[F].RelS:=9;End;
   4: Begin Voices[F].Atk:=60;Voices[F].DecS:=13;Voices[F].Sus:=24000;Voices[F].RelS:=10;End;
   6: Begin Voices[F].Atk:=32767;Voices[F].DecS:=8;Voices[F].Sus:=0;Voices[F].RelS:=8;
           Voices[F].Inc:=NoteInc[102];End;
  Else Begin Voices[F].Atk:=8000;Voices[F].DecS:=13;Voices[F].Sus:=0;Voices[F].RelS:=9;End;
  End;
End;

Procedure SynthNoteOff(Ch,Nt: Integer);
Var I: Integer;
Begin
 If Ch=10 Then Exit;
 For I:=1 To NVoice Do
  If Voices[I].Used And (Voices[I].Chan=Ch) And (Voices[I].Note=Nt)
     And (Voices[I].Stage<2) Then Voices[I].Stage:=2;
End;

Procedure SynthAllOff;
Var I: Integer;
Begin
 For I:=1 To NVoice Do
  If Voices[I].Used Then Voices[I].Stage:=2;
End;

Procedure SynthRender(Buf: PSmallArr; N: Integer);
Var K,I,Idx,W,Nz: Integer; Mix: LongInt; V: ^TVoice;
Begin
 For K:=0 To N-1 Do Begin
  Mix:=0;
  For I:=1 To NVoice Do
   If Voices[I].Used Then Begin
    V:=@Voices[I];
    Idx:=Integer(V^.Phase Shr 24);
    If V^.Timbre=5 Then Begin
     V^.Seed:=V^.Seed*1664525+1013904223;
     Nz:=Integer(V^.Seed Shr 17)-16384;
     Case V^.Kind Of
      1,4: Begin
            W:=SinTab[Idx];
            If V^.Inc>V^.IncMin Then V^.Inc:=V^.Inc-(V^.Inc Shr 11);
           End;
      2: W:=Nz Div 2+SinTab[Idx] Div 4;
      3: Begin W:=Nz-Integer(V^.Prev);V^.Prev:=Nz;End;
      5: If Idx<128 Then W:=16000 Else W:=-16000;
     Else W:=Nz;
     End;
     V^.Phase:=V^.Phase+V^.Inc;
    End Else Begin
     Case V^.Timbre Of
      1: W:=SinTab[Idx]+SinTab[(Idx*2) And 255] Div 6;
      2: W:=(Idx*256-32768) Div 2+SinTab[Idx] Div 3;
      3: If Idx<128 Then W:=(18000+SinTab[Idx]) Div 2 Else W:=(-18000+SinTab[Idx]) Div 2;
      4: W:=(Idx*256-32768) Div 2+SinTab[(Idx*2) And 255] Div 4;
      6: W:=SinTab[Idx];
     Else W:=(SinTab[Idx]+SinTab[(Idx*2) And 255] Div 2+
              SinTab[(Idx*3) And 255] Div 3) Div 2;
     End;
     V^.Phase:=V^.Phase+V^.Inc;
    End;
    { enveloppe }
    Case V^.Stage Of
     0: Begin
         V^.Level:=V^.Level+V^.Atk;
         If V^.Level>=32767 Then Begin V^.Level:=32767;V^.Stage:=1;End;
        End;
     1: If V^.Level>V^.Sus Then Begin
         V^.Level:=V^.Level-(V^.Level Shr V^.DecS)-1;
         If V^.Level<V^.Sus Then V^.Level:=V^.Sus;
         If (V^.Sus=0) And (V^.Level<=8) Then V^.Used:=False;
        End;
    Else Begin
         V^.Level:=V^.Level-(V^.Level Shr V^.RelS)-1;
         If V^.Level<=0 Then Begin V^.Level:=0;V^.Used:=False;End;
        End;
    End;
    Mix:=Mix+(((LongInt(W)*V^.Level) Div 32768)*V^.Amp) Div 127;
   End;
  Mix:=Mix Div 3;
  If Mix>32767 Then Mix:=32767;
  If Mix<-32767 Then Mix:=-32767;
  Buf^[K]:=SmallInt(Mix);
 End;
End;

{ remplit les tampons libres ; appele par le moteur a chaque passage }
Procedure SynthPump;
Var J: Integer;
Begin
 If Not WaveOpened Then Exit;
 For J:=0 To NSlots-1 Do
  If SynSlots[J].Prepared And
     ((SynSlots[J].Head.dwFlags And WHDR_INQUEUE)=0) Then Begin
   SynthRender(PSmallArr(@SynSlots[J].Data),SynthBlock Div 2);
   SynSlots[J].Head.dwBufferLength:=SynthBlock;
   waveOutWrite(WaveHandle,@SynSlots[J].Head,SizeOf(TWaveHdr));
  End;
End;
{$POP}
{$ENDIF}

Procedure SpeakerSet(F: Word);
Begin
 If F=SpkFreq Then Exit;
 SpkFreq:=F;
 {$IFNDEF MSWINDOWS}
 If F=0 Then NoSound Else Sound(F);
 {$ENDIF}
End;

Procedure SpeakerUpdate;
Var I,Hi: Integer; F: LongInt;
Begin
 {$IFDEF MSWINDOWS}
 If OutDev=0 Then SynthPump;
 Exit;
 {$ENDIF}
 If OutDev<>0 Then Begin SpeakerSet(0);Exit;End;
 If NowCs<ClickUntil Then Begin SpeakerSet(1200);Exit;End;
 Hi:=-1;
 For I:=1 To MAXSND Do
  If Snd[I].Used And (Snd[I].Chan<>10) Then
   If Snd[I].Note>Hi Then Hi:=Snd[I].Note;
 If Hi<0 Then Begin
  For I:=1 To MAXSND Do
   If Snd[I].Used And (Snd[I].Chan=10) Then Hi:=0;
  If Hi=0 Then Begin SpeakerSet(110);Exit;End;
  SpeakerSet(0);Exit;
 End;
 F:=(LongInt(SpkBase[Hi Mod 12])*(1 Shl (Hi Div 12))) Div 100;
 If F<40 Then F:=40;
 If F>12000 Then F:=12000;
 SpeakerSet(F);
End;

Procedure SndOn(Port1,Chan,Note,Vel: Byte; OffAt: LongInt; UseCs: Boolean);
Var I,F: Integer;
Begin
 {$IFDEF MSWINDOWS}
 If OutDev=0 Then SynthNoteOn(Chan,Note,Vel,ChanTimbre[Chan]);
 {$ENDIF}
 F:=0;I:=1;
 While (F=0) And (I<=MAXSND) Do Begin
  If Not Snd[I].Used Then F:=I;
  Inc(I);
 End;
 If F=0 Then F:=1;
 Snd[F].Used:=True;Snd[F].Port:=Port1;Snd[F].Chan:=Chan;Snd[F].Note:=Note;
 Snd[F].OffAt:=OffAt;Snd[F].UseCs:=UseCs;
 MidiSend(Port1,$90+(Chan-1),Note,Vel,3);
End;

Procedure SndOff(I: Integer);
Begin
 If Not Snd[I].Used Then Exit;
 {$IFDEF MSWINDOWS}
 If OutDev=0 Then SynthNoteOff(Snd[I].Chan,Snd[I].Note);
 {$ENDIF}
 MidiSend(Snd[I].Port,$80+(Snd[I].Chan-1),Snd[I].Note,0,3);
 Snd[I].Used:=False;
End;

Procedure AllNotesOff;
Var I: Integer; {$IFNDEF FPC} C: Integer; {$ENDIF}
Begin
 For I:=1 To MAXSND Do SndOff(I);
 For I:=1 To 32 Do Pend[I].Used:=False;
 {$IFDEF MSWINDOWS}
 SynthAllOff;
 {$ENDIF}
 {$IFNDEF FPC}
 If OutDev=1 Then
  For C:=0 To 15 Do Begin MpuWrite($B0+C);MpuWrite(123);MpuWrite(0);End;
 {$ENDIF}
 SpeakerSet(0);
End;

Procedure ResetDevices;
{$IFNDEF FPC}
Var C: Integer;
{$ENDIF}
Begin
 AllNotesOff;
 {$IFNDEF FPC}
 If OutDev=1 Then
  For C:=0 To 15 Do Begin
   MpuWrite($B0+C);MpuWrite(121);MpuWrite(0);
   MpuWrite($B0+C);MpuWrite(64);MpuWrite(0);
  End;
 {$ENDIF}
End;

Procedure UpdateSolo;
Var I: Integer;
Begin
 SoloAny:=False;
 For I:=1 To NTRK Do If Trk[I].Solo Then SoloAny:=True;
End;

Function Audible(Tk: Integer): Boolean;
Begin
 If FlEdSolo And (View<>V_ARR) And (EdPart>=1) And Parts[EdPart].Used Then Begin
  Audible:=(Tk=Parts[EdPart].Trk);Exit;
 End;
 If SoloAny Then Audible:=Trk[Tk].Solo And Not Trk[Tk].Mute
 Else Audible:=Not Trk[Tk].Mute;
End;

{ ---- parametres de lecture cumules (partie + piste + arrangement) ---- }

Function SumTrans(PI: Integer): Integer;
Begin
 SumTrans:=Parts[PI].PP.Trans+Trk[Parts[PI].Trk].PP.Trans+ArrPP.Trans;
End;

Function SumVel(PI: Integer): Integer;
Begin
 SumVel:=Parts[PI].PP.Vel+Trk[Parts[PI].Trk].PP.Vel+ArrPP.Vel;
End;

Function SumDly(PI: Integer): Integer;
Begin
 SumDly:=Parts[PI].PP.Dly+Trk[Parts[PI].Trk].PP.Dly+ArrPP.Dly;
End;

Function SumLen(PI: Integer): LongInt;
Begin
 SumLen:=(LongInt(Parts[PI].PP.LenP)*Trk[Parts[PI].Trk].PP.LenP Div 100)*
          ArrPP.LenP Div 100;
End;

Function SumComp(PI: Integer): Integer;
Begin
 SumComp:=Parts[PI].PP.Comp+Trk[Parts[PI].Trk].PP.Comp+ArrPP.Comp;
End;

Function FiltBit(K: Byte): Integer;
Var I: Integer;
Begin
 FiltBit:=-1;
 For I:=0 To 5 Do If FiltKind[I]=K Then FiltBit:=I;
End;

{ Envoie un evenement non-note }
Procedure SendCtl(Tk: Integer; Var E: TEvt);
Var Ch: Byte;
Begin
 Ch:=Trk[Tk].Chan-1;
 Case E.Kind Of
  EK_CTRL: MidiSend(Trk[Tk].Outp,$B0+Ch,E.D1,E.D2,3);
  EK_PROG: MidiSend(Trk[Tk].Outp,$C0+Ch,E.D1,0,2);
  EK_BEND: MidiSend(Trk[Tk].Outp,$E0+Ch,E.D1,E.D2,3);
  EK_CHANP: MidiSend(Trk[Tk].Outp,$D0+Ch,E.D1,0,2);
  EK_POLYP: MidiSend(Trk[Tk].Outp,$A0+Ch,E.D1,E.D2,3);
 End;
End;

{ Declenche un evenement de partie }
Procedure FireEv(PI: Integer; Var E: TEvt; Te: LongInt);
Var Tk,B,Note,Vel,Cm: Integer; L: LongInt;
Begin
 Tk:=Parts[PI].Trk;
 B:=FiltBit(E.Kind);
 If (B>=0) And ((Trk[Tk].Filt And (1 Shl B))<>0) Then Exit;
 If E.Kind=EK_NOTE Then Begin
  Note:=E.D1;
  If Not Trk[Tk].Drum Then Note:=Note+SumTrans(PI);
  If (Note<0) Or (Note>127) Then Exit;
  Vel:=E.D2+SumVel(PI);
  Cm:=SumComp(PI);
  If Cm<>0 Then Vel:=Vel+((64-Vel)*Cm) Div 100;
  If HumVel>0 Then Vel:=Vel+Random(HumVel*2+1)-HumVel;
  Vel:=Integer(Clamp(Vel,1,127));
  L:=E.Len*SumLen(PI) Div 100;
  If HumLen>0 Then L:=L+L*(Random(HumLen*2+1)-HumLen) Div 100;
  If L<1 Then L:=1;
  SndOn(Trk[Tk].Outp,Trk[Tk].Chan,Note,Vel,Te+L,False);
 End Else SendCtl(Tk,E);
End;

Procedure SendSetup;
Var Tk,I,P,Pg: Integer; Used: Array[1..NTRK] Of Boolean;
Begin
 FillChar(Used,SizeOf(Used),0);
 For I:=1 To MAXPART Do If Parts[I].Used Then Used[Parts[I].Trk]:=True;
 For Tk:=1 To NTRK Do
  If Used[Tk] Then Begin
   {$IFDEF MSWINDOWS}
   ChanTimbre[Trk[Tk].Chan]:=TimbreOf(Trk[Tk].Instr);
   {$ENDIF}
   Pg:=Trk[Tk].PP.Prg;
   If (Pg<0) And (Not Trk[Tk].Drum) Then Pg:=ProgOf(Trk[Tk].Instr);
   If Pg>=0 Then MidiSend(Trk[Tk].Outp,$C0+Trk[Tk].Chan-1,Pg,0,2);
   P:=Trk[Tk].PP.Vol;
   If P>=0 Then MidiSend(Trk[Tk].Outp,$B0+Trk[Tk].Chan-1,7,P,3);
  End;
End;

{ Positionne les curseurs de lecture de chaque partie }
Procedure PlaySeek(Tick: LongInt);
Var PI,Tk: Integer; Dl: LongInt;
Begin
 For PI:=1 To MAXPART Do
  If Parts[PI].Used Then Begin
   Tk:=Parts[PI].Trk;
   Dl:=SumDly(PI);
   Parts[PI].Cur:=1;
   While (Parts[PI].Cur<=Parts[PI].Cnt) And
         (Parts[PI].Start+Parts[PI].Ev^[Parts[PI].Cur].T+Dl<Tick) Do Begin
    If FlChase And Audible(Tk) And (Not Parts[PI].Mute) And
       (Parts[PI].Ev^[Parts[PI].Cur].Kind<>EK_NOTE) Then
      FireEv(PI,Parts[PI].Ev^[Parts[PI].Cur],Tick);
    Inc(Parts[PI].Cur);
   End;
  End;
End;

Procedure FireUpTo(NewTick: LongInt);
Var PI,Tk: Integer; Dl,Te: LongInt; Aud,Go: Boolean;
Begin
 For PI:=1 To MAXPART Do
  If Parts[PI].Used And (Parts[PI].Ev<>Nil) Then Begin
   Tk:=Parts[PI].Trk;
   Dl:=SumDly(PI);
   If Parts[PI].Cur<1 Then Parts[PI].Cur:=1;
   If Parts[PI].Cur>Parts[PI].Cnt+1 Then Parts[PI].Cur:=Parts[PI].Cnt+1;
   If Parts[PI].Start+Dl<=NewTick Then Begin
    Aud:=Audible(Tk) And (Not Parts[PI].Mute);
    Go:=True;
    While Go And (Parts[PI].Cur<=Parts[PI].Cnt) Do Begin
     Te:=Parts[PI].Start+Parts[PI].Ev^[Parts[PI].Cur].T;
     If Te>=Parts[PI].Stop Then Parts[PI].Cur:=Parts[PI].Cnt+1
     Else If Te+Dl>=NewTick Then Go:=False
     Else Begin
      If Aud Then FireEv(PI,Parts[PI].Ev^[Parts[PI].Cur],Te+Dl);
      Inc(Parts[PI].Cur);
     End;
    End;
   End;
  End;
End;

Procedure StopPlay; Forward;

Procedure Click(Strong: Boolean);
Begin
 ClickUntil:=NowCs+4;
 {$IFDEF MSWINDOWS}
 If OutDev=0 Then Begin
  If Strong Then SynthNoteOn(1,ClkHi,ClkVel+10,6) Else SynthNoteOn(1,ClkLo,ClkVel,6);
 End;
 {$ENDIF}
 {$IFNDEF FPC}
 If OutDev=1 Then Begin
  MpuWrite($90+ClkChan-1);
  If Strong Then MpuWrite(ClkHi) Else MpuWrite(ClkLo);
  MpuWrite(ClkVel);
 End;
 {$ENDIF}
End;

{ ---- enregistrement ---- }

Function RecPartFor(T: LongInt): Integer;
Var P: Integer; B: LongInt;
Begin
 P:=RecPart;
 If (P<1) Or (Not Parts[P].Used) Then P:=PartAt(RecTrk,T);
 If P=0 Then Begin
  B:=FloorDiv(T,BarTicks)*BarTicks;
  P:=PartNew(RecTrk,B,B+BarTicks,Trk[RecTrk].Name);
 End;
 If P>0 Then Begin
  RecPart:=P;
  If T>=Parts[P].Stop Then
   Parts[P].Stop:=(FloorDiv(T,BarTicks)+1)*BarTicks;
  If T<Parts[P].Start Then RecPart:=0;
 End;
 RecPartFor:=RecPart;
End;

Procedure RecNoteOn(Pitch,Vel: Integer; Len: LongInt);
Var P,I: Integer;
Begin
 If (Not Playing) Or (Not Recording) Or CountInOn Then Exit;
 If (Trk[RecTrk].Filt And 1)<>0 Then Exit;
 If FlPunch And ((PlayTick<LocL) Or (PlayTick>=LocR)) Then Exit;
 P:=RecPartFor(PlayTick);
 If P=0 Then Exit;
 I:=EvAdd(P,PlayTick-Parts[P].Start,Len,EK_NOTE,Pitch,Vel);
 If I>0 Then Begin
  RecStart[Pitch]:=PlayTick;
  If I<=Parts[P].Cur Then Inc(Parts[P].Cur);
  Parts[P].Ev^[I].Sel:=True;
  NeedDraw:=True;
 End;
End;

Procedure RecNoteOff(Pitch: Integer);
Var P,I: Integer; L: LongInt; Fnd: Boolean;
Begin
 If (Not Playing) Or (Not Recording) Then Exit;
 If RecStart[Pitch]<0 Then Exit;
 P:=RecPart;
 If (P<1) Or (Not Parts[P].Used) Then Exit;
 I:=Parts[P].Cnt;Fnd:=False;
 While (I>=1) And Not Fnd Do Begin
  If (Parts[P].Ev^[I].Kind=EK_NOTE) And (Parts[P].Ev^[I].D1=Pitch) And
     (Parts[P].Start+Parts[P].Ev^[I].T=RecStart[Pitch]) Then Begin
   L:=PlayTick-RecStart[Pitch];
   If L<1 Then L:=1;
   Parts[P].Ev^[I].Len:=L;
   Fnd:=True;
  End;
  Dec(I);
 End;
 RecStart[Pitch]:=-1;
 NeedDraw:=True;
End;

Procedure RecCtl(K,D1,D2: Integer);
Var P,B: Integer;
Begin
 If (Not Playing) Or (Not Recording) Or CountInOn Then Exit;
 B:=FiltBit(K);
 If (B>=0) And ((Trk[RecTrk].Filt And (1 Shl B))<>0) Then Exit;
 P:=RecPartFor(PlayTick);
 If P=0 Then Exit;
 B:=EvAdd(P,PlayTick-Parts[P].Start,0,K,D1,D2);
 If (B>0) And (B<=Parts[P].Cur) Then Inc(Parts[P].Cur);
 NeedDraw:=True;
End;

Procedure QuantizePart(P: Integer; OnlySel: Boolean; Q: LongInt);
Var I: Integer;
Begin
 If (Q<=1) Or (Parts[P].Ev=Nil) Then Exit;
 For I:=1 To Parts[P].Cnt Do
  If (Not OnlySel) Or Parts[P].Ev^[I].Sel Then
   Parts[P].Ev^[I].T:=Quant(Parts[P].Ev^[I].T,Q);
 PartSort(P);
End;

Procedure SaveUndo;
Forward;

{ ---- avance du temps ---- }

Procedure AdvanceTo(NewTick: LongInt);
Var B: LongInt; I: Integer; Strong: Boolean;
Begin
 If FlCycle And (Not CountInOn) And (LocR>LocL) And (NewTick>=LocR) Then Begin
  NewTick:=LocL+(NewTick-LocR);
  AllNotesOff;
  PlaySeek(NewTick);
  LastBeat:=FloorDiv(NewTick,BeatTicks)-1;
  If Recording And (CycMode=1) And (RecPart>0) And Parts[RecPart].Used Then
   For I:=Parts[RecPart].Cnt DownTo 1 Do
    If Parts[RecPart].Ev^[I].Sel Then EvDel(RecPart,I);
 End;
 If (Not Recording) And (Not CountInOn) And (NewTick>=SongEnd) Then Begin
  StopPlay;Exit;
 End;
 B:=FloorDiv(NewTick,BeatTicks);
 If B<>LastBeat Then Begin
  LastBeat:=B;
  Strong:=(FloorDiv(NewTick,BeatTicks) Mod SigN)=0;
  If CountInOn Then Click(Strong)
  Else If FlClick Then
   If (ClickMode=0) Or ((ClickMode=1) And Recording) Or
      ((ClickMode=2) And (Not Recording)) Then Click(Strong);
 End;
 If CountInOn And (NewTick>=PosTick) Then Begin
  CountInOn:=False;
  PlaySeek(PosTick);
 End;
 If Not CountInOn Then FireUpTo(NewTick);
 PlayTick:=NewTick;
 If Recording And (RecPart>0) And Parts[RecPart].Used Then
  If PlayTick>=Parts[RecPart].Stop Then
   Parts[RecPart].Stop:=(FloorDiv(PlayTick,BarTicks)+1)*BarTicks;
End;

Procedure StartPlay(From: LongInt);
Var I: Integer;
Begin
 If Playing Then Exit;
 If From<0 Then From:=0;
 UpdateSolo;
 AllNotesOff;
 FillChar(Snd,SizeOf(Snd),0);
 FillChar(Pend,SizeOf(Pend),0);
 For I:=0 To 127 Do RecStart[I]:=-1;
 SendSetup;
 PosTick:=From;
 CountInOn:=False;
 RecPart:=0;RecT0:=From;RecTrk:=CurTrk;
 If Recording Then SaveUndo;
 If Recording And (CountIn>0) Then Begin
  CountInOn:=True;
  PlayTick:=From-CountIn*BarTicks;
  PlaySeek(From);
 End Else Begin
  PlayTick:=From;
  PlaySeek(From);
 End;
 RemT:=0;LastCs:=NowCs;
 LastBeat:=FloorDiv(PlayTick,BeatTicks)-1;
 Playing:=True;
 PlayShown:=-1;
 NeedDraw:=True;
End;

Procedure StopPlay;
Var I,P: Integer; E1: LongInt;
Begin
 If Not Playing Then Begin
  PosTick:=LocL;
  NeedDraw:=True;
  Exit;
 End;
 Playing:=False;
 If PlayTick>=0 Then PosTick:=PlayTick;
 CountInOn:=False;
 AllNotesOff;
 FillChar(Snd,SizeOf(Snd),0);
 If FlReset Then ResetDevices;
 If Recording Then Begin
  Recording:=False;
  P:=RecPart;
  If (P>=1) And Parts[P].Used Then Begin
   E1:=PlayTick;
   If (Not FlOverdub) Then
    For I:=Parts[P].Cnt DownTo 1 Do
     If (Not Parts[P].Ev^[I].Sel) And
        (Parts[P].Start+Parts[P].Ev^[I].T>=RecT0) And
        (Parts[P].Start+Parts[P].Ev^[I].T<E1) Then EvDel(P,I);
   If AutoQ>0 Then QuantizePart(P,True,QuaTk[AutoQ]);
   For I:=1 To Parts[P].Cnt Do Parts[P].Ev^[I].Sel:=False;
   If Parts[P].Cnt=0 Then PartFree(P);
   Modified:=True;
  End;
  RecPart:=0;
 End;
 If FlFollow Then PosTick:=PosTick;
 NeedDraw:=True;
End;

{ ---- entree en direct ---- }

Function EchoCs(Ticks: LongInt): LongInt;
Var V: Integer;
Begin
 V:=TempoAt(CurPos);
 If V<1 Then V:=1;
 EchoCs:=Round(Ticks*60000.0/(LongInt(V)*PPQ));
End;

Procedure PendAdd(DelayCs: LongInt; Port1,Chan,Note,Vel: Byte);
Var I: Integer;
Begin
 For I:=1 To 32 Do
  If Not Pend[I].Used Then Begin
   Pend[I].Used:=True;Pend[I].AtCs:=NowCs+DelayCs;Pend[I].Port:=Port1;
   Pend[I].Chan:=Chan;Pend[I].Note:=Note;Pend[I].Vel:=Vel;
   Exit;
  End;
End;

Procedure CmdStart; Forward;
Procedure CmdStop; Forward;

{ note jouee en direct sur la piste courante }
Procedure LiveNote(P,V: Integer; Held: Boolean);
Var Tk,R,Nn,Vv: Integer; D,Gap,Q: LongInt; Len: LongInt;
Begin
 If RemOn<>0 Then Begin
  If P=RemStart Then Begin CmdStart;Exit;End;
  If P=RemStop Then Begin CmdStop;Exit;End;
 End;
 Tk:=CurTrk;
 {$IFDEF MSWINDOWS}
 ChanTimbre[Trk[Tk].Chan]:=TimbreOf(Trk[Tk].Instr);
 {$ENDIF}
 If FlThru Or (Playing And Recording) Then
  If Held Then SndOn(Trk[Tk].Outp,Trk[Tk].Chan,P,V,NowCs+3000,True)
  Else SndOn(Trk[Tk].Outp,Trk[Tk].Chan,P,V,NowCs+30,True);
 If QuaTk[QuaI]>1 Then Len:=QuaTk[QuaI] Else Len:=PPQ Div 4;
 RecNoteOn(P,V,Len);
 If MpOn And (MpRep>0) Then Begin
  D:=0;Gap:=MpEcho*6;
  For R:=1 To MpRep Do Begin
   If Gap<3 Then Gap:=3;
   D:=D+Gap;
   Q:=D;
   If MpQuant>0 Then Q:=Quant(D,QuaTk[MpQuant]);
   If Q<1 Then Q:=1;
   Nn:=P+R*MpNDec;Vv:=V+R*MpVDec;
   If (Nn>=0) And (Nn<=127) Then Begin
    If MpChan>0 Then PendAdd(EchoCs(Q),Trk[Tk].Outp,MpChan,Nn,Integer(Clamp(Vv,1,127)))
    Else PendAdd(EchoCs(Q),Trk[Tk].Outp,Trk[Tk].Chan,Nn,Integer(Clamp(Vv,1,127)));
   End;
   Gap:=Gap+MpEDec*6;
  End;
 End;
End;

Procedure LiveOff(P: Integer);
Var I,Tk: Integer;
Begin
 Tk:=CurTrk;
 For I:=1 To MAXSND Do
  If Snd[I].Used And (Snd[I].Note=P) And (Snd[I].Chan=Trk[Tk].Chan) And
     Snd[I].UseCs Then Begin SndOff(I);End;
 RecNoteOff(P);
End;

Function PianoKey(K: Word): Integer;
Const
 Low  : String[17] = 'zsxdcvgbhnjm,l.;/';
 Up   : String[17] = 'q2w3er5t6y7ui9o0p';
Var Ch: Char; I: Integer;
Begin
 PianoKey:=-1;
 If K>255 Then Exit;
 Ch:=Chr(K);
 If (Ch>='A') And (Ch<='Z') Then Ch:=Chr(Ord(Ch)+32);
 I:=Pos(Ch,Low);
 If I>0 Then Begin PianoKey:=Oct*12+12+I-1;Exit;End;
 I:=Pos(Ch,Up);
 If I>0 Then PianoKey:=Oct*12+24+I-1;
End;

{$IFNDEF FPC}
Procedure HandleMidiIn(St,D1,D2: Integer);
Var Ch: Integer;
Begin
 Ch:=(St And 15)+1;
 If (MidiInChan>0) And (Ch<>MidiInChan) Then Exit;
 Case St Shr 4 Of
  9: If D2>0 Then Begin
      If FlThru Then LiveNote(D1,D2,True) Else RecNoteOn(D1,D2,PPQ Div 4);
     End Else LiveOff(D1);
  8: LiveOff(D1);
  11: RecCtl(EK_CTRL,D1,D2);
  14: RecCtl(EK_BEND,D1,D2);
  13: RecCtl(EK_CHANP,D1,0);
 End;
End;

Procedure PollMpuIn;
Var B,N: Integer;
Begin
 If OutDev<>1 Then Exit;
 N:=0;
 While ((Port[MpuPort+1] And $80)=0) And (N<64) Do Begin
  Inc(N);
  B:=Port[MpuPort];
  If B>=$F8 Then Begin End
  Else If B>=$80 Then Begin InSt:=B;InN:=0;End
  Else Begin
   If InN=0 Then Begin
    InD1:=B;
    If ((InSt And $F0)=$C0) Or ((InSt And $F0)=$D0) Then Begin
     HandleMidiIn(InSt,InD1,0);
    End Else InN:=1;
   End Else Begin
    InN:=0;
    HandleMidiIn(InSt,InD1,B);
   End;
  End;
 End;
End;
{$ENDIF}

Procedure EngineStep;
Var Now1,D,Adv: LongInt; I: Integer;
Begin
 {$IFNDEF FPC}
 PollMpuIn;
 {$ENDIF}
 Now1:=NowCs;
 For I:=1 To MAXSND Do
  If Snd[I].Used And Snd[I].UseCs Then
   If Now1>=Snd[I].OffAt Then SndOff(I);
 For I:=1 To 32 Do
  If Pend[I].Used And (Now1>=Pend[I].AtCs) Then Begin
   Pend[I].Used:=False;
   SndOn(Pend[I].Port,Pend[I].Chan,Pend[I].Note,Pend[I].Vel,Now1+30,True);
   If Playing And Recording Then
    RecNoteOn(Pend[I].Note,Pend[I].Vel,PPQ Div 4);
  End;
 If Playing Then Begin
  D:=Now1-LastCs;
  If D<0 Then D:=D+8640000;
  If D<0 Then D:=0;
  LastCs:=Now1;
  If D>30 Then D:=30;
  RemT:=RemT+D*TempoAt(PlayTick)*PPQ;
  Adv:=RemT Div 60000;
  RemT:=RemT Mod 60000;
  If Adv>0 Then Begin
   AdvanceTo(PlayTick+Adv);
   If Playing Then
    For I:=1 To MAXSND Do
     If Snd[I].Used And (Not Snd[I].UseCs) Then
      If PlayTick>=Snd[I].OffAt Then SndOff(I);
  End;
 End;
 SpeakerUpdate;
End;


{ ====================================================================== }
{                       ELEMENTS D'INTERFACE                             }
{ ====================================================================== }

Procedure Cell(X1,Y1,X2,Y2: Integer; Const Val,Lbl: String; Inv: Boolean);
Begin
 If Inv Then Box(X1,Y1,X2,Y2,INK) Else Begin
  Box(X1,Y1,X2,Y2,PAPER);Frame(X1,Y1,X2,Y2);End;
 If Lbl<>'' Then Begin
  If Inv Then WText((X1+X2+1-TextW(Lbl)) Div 2,Y2-9,Lbl)
  Else PText((X1+X2+1-TextW(Lbl)) Div 2,Y2-9,Lbl);
 End;
 If Inv Then WText((X1+X2+1-TextW(Val)) Div 2,Y1+4,Val)
 Else BText((X1+X2+1-TextW(Val)) Div 2,Y1+4,Val);
End;

{ case de valeur : cadre + texte centre }
Procedure ValBox(X1,Y1,X2,Y2: Integer; Const S: String; Inv: Boolean);
Begin
 If Inv Then Begin
  Box(X1,Y1,X2,Y2,INK);
  WText((X1+X2+1-TextW(S)) Div 2,(Y1+Y2-6) Div 2,S);
 End Else Begin
  Box(X1,Y1,X2,Y2,PAPER);Frame(X1,Y1,X2,Y2);
  BText((X1+X2+1-TextW(S)) Div 2,(Y1+Y2-6) Div 2,S);
 End;
End;

Procedure Info(Const En,Fr,De: String);
Begin
 MsgBox('CUBASE',T3(En,Fr,De));
End;

{ barre de titre d'une fenetre }
Procedure DrawTitle(Const S: String);
Begin
 Box(0,TB_Y,SCR_W-1,TB_Y+TB_H-1,PAPER);
 PatBar(20,TB_Y+1,SCR_W-18,TB_Y+TB_H-2,PatLight);
 Frame(0,TB_Y,SCR_W-1,TB_Y+TB_H-1);
 SmallBox(0,TB_Y);
 Box(SCR_W Div 2-TextW(S) Div 2-8,TB_Y+1,SCR_W Div 2+TextW(S) Div 2+8,TB_Y+TB_H-2,PAPER);
 BText(SCR_W Div 2-TextW(S) Div 2,TB_Y+5,S);
 SmallBox(SCR_W-18,TB_Y);
End;

{ ---- ascenseurs ---- }

Procedure ScrollBarDraw(Vert: Boolean; X1,Y1,X2,Y2: Integer;
                        Pos,Total,Vis: LongInt);
Var TL,TS,TE,Th,Tp: LongInt;
Begin
 Box(X1,Y1,X2,Y2,PAPER);
 Frame(X1,Y1,X2,Y2);
 If Vert Then Begin
  ArrowBox(X1,Y1,X2,Y1+15,1);
  ArrowBox(X1,Y2-15,X2,Y2,2);
  TS:=Y1+16;TE:=Y2-16;
 End Else Begin
  ArrowBox(X1,Y1,X1+15,Y2,3);
  ArrowBox(X2-15,Y1,X2,Y2,4);
  TS:=X1+16;TE:=X2-16;
 End;
 TL:=TE-TS+1;
 If (Total<=Vis) Or (TL<8) Then Begin
  PatBar(Integer(Min2(X1+1,X2)),Integer(Min2(Y1+1,Y2)),X2,Y2,PatLight);
  Exit;
 End;
 PatBar(X1+Ord(Not Vert)*16+1,Y1+Ord(Vert)*16+1,X2-Ord(Not Vert)*16-1,
        Y2-Ord(Vert)*16-1,PatLight);
 Th:=TL*Vis Div Total;
 If Th<12 Then Th:=12;
 Tp:=TS+(TL-Th)*Pos Div (Total-Vis);
 If Vert Then Begin
  Box(X1+1,Integer(Tp),X2-1,Integer(Tp+Th),PAPER);
  Frame(X1+1,Integer(Tp),X2-1,Integer(Tp+Th));
 End Else Begin
  Box(Integer(Tp),Y1+1,Integer(Tp+Th),Y2-1,PAPER);
  Frame(Integer(Tp),Y1+1,Integer(Tp+Th),Y2-1);
 End;
End;

{ nouvelle position pour un clic dans l'ascenseur (-1 = pas de changement) }
Function ScrollClick(Vert: Boolean; X1,Y1,X2,Y2: Integer; MXp,MYp: Integer;
                     Pos,Total,Vis: LongInt): LongInt;
Var TL,TS,TE,Th,Tp,M,P: LongInt;
Begin
 ScrollClick:=-1;
 If Vert Then Begin TS:=Y1+16;TE:=Y2-16;M:=MYp;End
 Else Begin TS:=X1+16;TE:=X2-16;M:=MXp;End;
 P:=Pos;
 If (Vert And (MYp<TS)) Or ((Not Vert) And (MXp<TS)) Then P:=Pos-1
 Else If (Vert And (MYp>TE)) Or ((Not Vert) And (MXp>TE)) Then P:=Pos+1
 Else Begin
  TL:=TE-TS+1;
  If Total<=Vis Then Exit;
  Th:=TL*Vis Div Total;
  If Th<12 Then Th:=12;
  Tp:=TS+(TL-Th)*Pos Div (Total-Vis);
  If M<Tp Then P:=Pos-Vis
  Else If M>Tp+Th Then P:=Pos+Vis
  Else Exit;
 End;
 If P<0 Then P:=0;
 If P>Total-Vis Then P:=Total-Vis;
 If P<0 Then P:=0;
 ScrollClick:=P;
End;

{ position pendant le glissement du curseur }
Function ScrollDrag(Vert: Boolean; X1,Y1,X2,Y2: Integer; MXp,MYp: Integer;
                    Total,Vis: LongInt): LongInt;
Var TL,TS,TE,Th,M,P: LongInt;
Begin
 If Vert Then Begin TS:=Y1+16;TE:=Y2-16;M:=MYp;End
 Else Begin TS:=X1+16;TE:=X2-16;M:=MXp;End;
 TL:=TE-TS+1;
 Th:=TL*Vis Div Total;
 If Th<12 Then Th:=12;
 If (Total<=Vis) Or (TL<=Th) Then Begin ScrollDrag:=0;Exit;End;
 P:=((M-TS-Th Div 2)*(Total-Vis)) Div (TL-Th);
 If P<0 Then P:=0;
 If P>Total-Vis Then P:=Total-Vis;
 ScrollDrag:=P;
End;

{ ====================================================================== }
{                          TABLEAU DE TRANSPORT                          }
{ ====================================================================== }

Function SmpteStr(T: LongInt): String;
Var Ms,H,M,S,F: LongInt;
Begin
 Ms:=TickMs(Max2(0,T));
 H:=Ms Div 3600000;M:=(Ms Div 60000) Mod 60;S:=(Ms Div 1000) Mod 60;
 F:=(Ms Mod 1000) Div 40;
 SmpteStr:=IntStr(H)+':'+PadL(IntStr(M),2)+':'+PadL(IntStr(S),2)+':'+
           PadL(IntStr(F),2);
End;

Function SyncLbl: String;
Begin
 Case SyncMode Of
  1: SyncLbl:='MIDI';
  2: SyncLbl:='SMPTE';
 Else SyncLbl:='INT';
 End;
End;

Procedure TapeIcon(X1,Y1,X2,Y2,K: Integer; Hot: Boolean);
Var Pt: Array[1..3] Of PointType; CX,CY,C: Integer;
Begin
 If Hot Then Begin Box(X1,Y1,X2,Y2,INK);C:=PAPER;End
 Else Begin Box(X1,Y1,X2,Y2,PAPER);Frame(X1,Y1,X2,Y2);C:=INK;End;
 CX:=(X1+X2) Div 2;CY:=(Y1+Y2) Div 2;
 SetColor(C);SetFillStyle(SolidFill,C);
 Case K Of
  1: Begin
      Pt[1].X:=CX;Pt[1].Y:=CY-6;Pt[2].X:=CX;Pt[2].Y:=CY+6;Pt[3].X:=CX-8;Pt[3].Y:=CY;
      FillPoly(3,Pt);
      Pt[1].X:=CX+8;Pt[1].Y:=CY-6;Pt[2].X:=CX+8;Pt[2].Y:=CY+6;Pt[3].X:=CX;Pt[3].Y:=CY;
      FillPoly(3,Pt);
     End;
  2: Begin
      Pt[1].X:=CX;Pt[1].Y:=CY-6;Pt[2].X:=CX;Pt[2].Y:=CY+6;Pt[3].X:=CX+8;Pt[3].Y:=CY;
      FillPoly(3,Pt);
      Pt[1].X:=CX-8;Pt[1].Y:=CY-6;Pt[2].X:=CX-8;Pt[2].Y:=CY+6;Pt[3].X:=CX;Pt[3].Y:=CY;
      FillPoly(3,Pt);
     End;
  3: Bar(CX-5,CY-5,CX+5,CY+5);
  4: Begin
      Pt[1].X:=CX-5;Pt[1].Y:=CY-7;Pt[2].X:=CX-5;Pt[2].Y:=CY+7;Pt[3].X:=CX+7;Pt[3].Y:=CY;
      FillPoly(3,Pt);
     End;
  5: FillEllipse(CX,CY,6,6);
 End;
End;

Procedure DrawPosCells;
Var T: LongInt;
Begin
 T:=CurPos;
 Cell(410,TR_Y,515,TR_Y+30,PosStr(T),'SONG POSITION',False);
 Cell(410,TR_Y+32,515,TR_Y+62,SmpteStr(T),'SMPTE TIME',False);
 PlayShown:=T;
End;

Procedure DrawTransport;
Var S: String;
Begin
 UpdateSolo;
 Box(0,TR_Y-2,SCR_W-1,SCR_H-1,PAPER);
 SetColor(INK);
 Line(0,TR_Y-2,SCR_W-1,TR_Y-2);
 Cell(0,TR_Y,51,TR_Y+30,'SOLO','',SoloAny);
 Cell(0,TR_Y+32,51,TR_Y+62,'EDSOLO','',FlEdSolo);
 If FlOverdub Then S:='OVERDUB' Else S:='REPLACE';
 Cell(53,TR_Y,118,TR_Y+30,S,'REC MODE',False);
 Cell(53,TR_Y+32,118,TR_Y+62,'CYCLE','',FlCycle);
 If FlPunch Then S:='IN/OUT' Else S:='---';
 Cell(120,TR_Y,181,TR_Y+30,S,'PUNCH',False);
 If FlMaster Then S:='ON' Else S:='OFF';
 Cell(120,TR_Y+32,181,TR_Y+62,S,'MASTER',False);
 Cell(183,TR_Y,286,TR_Y+30,PosStr(LocL),'LEFT LOCATOR',False);
 Cell(183,TR_Y+32,286,TR_Y+62,PosStr(LocR),'RIGHT LOCATOR',False);
 TapeIcon(288,TR_Y,346,TR_Y+30,1,False);
 TapeIcon(350,TR_Y,408,TR_Y+30,2,False);
 TapeIcon(288,TR_Y+32,326,TR_Y+62,3,False);
 TapeIcon(329,TR_Y+32,367,TR_Y+62,4,Playing);
 TapeIcon(370,TR_Y+32,408,TR_Y+62,5,Recording);
 DrawPosCells;
 Cell(517,TR_Y,577,TR_Y+30,IntStr(SigN)+'/'+IntStr(SigD),'SIGN',False);
 If FlMaster And (NTemp>0) Then S:=TempoStr(TempoAt(CurPos))
 Else S:=TempoStr(TempoFix);
 Cell(517,TR_Y+32,577,TR_Y+62,S,'TEMPO',False);
 Cell(579,TR_Y,SCR_W-1,TR_Y+30,'CLICK','',FlClick);
 Cell(579,TR_Y+32,SCR_W-1,TR_Y+62,SyncLbl,'SYNC',False);
End;

{ ====================================================================== }
{                       FENETRE D'ARRANGEMENT                            }
{ ====================================================================== }

Function BarPx: Integer;
Begin
 BarPx:=BarPxTab[ZoomI];
End;

Function VisBars: Integer;
Begin
 VisBars:=(AR_X1-AR_X0+1) Div BarPx;
End;

Function XOfTick(T: LongInt): Integer;
Var V: LongInt;
Begin
 V:=AR_X0+((T-ViewBar*BarTicks)*BarPx) Div BarTicks;
 If V<-30000 Then V:=-30000;
 If V>30000 Then V:=30000;
 XOfTick:=Integer(V);
End;

Function TickOfX(X: Integer): LongInt;
Begin
 TickOfX:=ViewBar*BarTicks+((LongInt(X)-AR_X0)*BarTicks) Div BarPx;
End;

Function TrkY(Tk: Integer): Integer;
Begin
 TrkY:=R0_Y+(Tk-ArrTop)*ROWH;
End;

Function TrkAtY(Y: Integer): Integer;
Var I: Integer;
Begin
 I:=ArrTop+(Y-R0_Y) Div ROWH;
 If (Y<R0_Y) Or (I<1) Or (I>NTRK) Or (I>=ArrTop+VISR) Then I:=0;
 TrkAtY:=I;
End;

Procedure ClipLine(X1,Y1,X2,Y2: Integer);
Begin
 If X1<AR_X0 Then X1:=AR_X0;
 If X2>AR_X1 Then X2:=AR_X1;
 If X1<=X2 Then Line(X1,Y1,X2,Y2);
End;

Procedure DrawPartBlock(P: Integer; Y: Integer);
Var X1,X2,Xa,Xb,K,Ex1,Ex2,Py,Nw,Tx: Integer; C: Integer;
Begin
 X1:=XOfTick(Parts[P].Start);
 X2:=XOfTick(Parts[P].Stop)-1;
 If (X2<AR_X0) Or (X1>AR_X1) Then Exit;
 Xa:=X1;If Xa<AR_X0 Then Xa:=AR_X0;
 Xb:=X2;If Xb>AR_X1 Then Xb:=AR_X1;
 If Parts[P].Sel Then Begin Box(Xa,Y+1,Xb,Y+ROWH-2,INK);C:=PAPER;End
 Else Begin
  If Parts[P].Mute Then PatBar(Xa,Y+1,Xb,Y+ROWH-2,PatLight)
  Else Box(Xa,Y+1,Xb,Y+ROWH-2,PAPER);
  C:=INK;
 End;
 SetColor(INK);SetLineStyle(SolidLn,0,1);
 ClipLine(X1,Y+1,X2,Y+1);
 ClipLine(X1,Y+ROWH-2,X2,Y+ROWH-2);
 If X1>=AR_X0 Then Line(X1,Y+1,X1,Y+ROWH-2);
 If X2<=AR_X1 Then Line(X2,Y+1,X2,Y+ROWH-2);
 Nw:=0;
 If (X2-X1)>=60 Then Begin
  Nw:=Length(Parts[P].Name)*8+6;
  If Nw>(X2-X1) Div 2 Then Nw:=((X2-X1) Div 2) Div 8*8+6;
  If Parts[P].Sel Then SetColor(PAPER) Else SetColor(INK);
  Tx:=X1+3;
  If Tx>=AR_X0 Then OutTextXY(Tx,Y+4,Copy(Parts[P].Name,1,(Nw-6) Div 8));
 End;
 If Parts[P].Ev<>Nil Then Begin
  SetColor(C);
  For K:=1 To Parts[P].Cnt Do
   If Parts[P].Ev^[K].Kind=EK_NOTE Then Begin
    Ex1:=XOfTick(Parts[P].Start+Parts[P].Ev^[K].T);
    Ex2:=XOfTick(Parts[P].Start+Parts[P].Ev^[K].T+Parts[P].Ev^[K].Len);
    If Ex2<=Ex1 Then Ex2:=Ex1;
    If Ex1<X1+Nw+1 Then Ex1:=X1+Nw+1;
    If Ex2>X2-2 Then Ex2:=X2-2;
    If (Ex1<=Ex2) And (Ex2>=AR_X0) And (Ex1<=AR_X1) Then Begin
     Py:=Y+ROWH-4-(Parts[P].Ev^[K].D1*(ROWH-8)) Div 127;
     If Ex1<AR_X0 Then Ex1:=AR_X0;
     If Ex2>AR_X1 Then Ex2:=AR_X1;
     Line(Ex1,Py,Ex2,Py);
    End;
   End;
 End;
End;

Procedure DrawLocFlag(X: Integer; Ch: Char);
Var Pt: Array[1..3] Of PointType;
Begin
 If (X<AR_X0) Or (X>AR_X1) Then Exit;
 Pt[1].X:=X;Pt[1].Y:=HD_B;Pt[2].X:=X-4;Pt[2].Y:=HD_B-7;Pt[3].X:=X+4;Pt[3].Y:=HD_B-7;
 SetFillStyle(SolidFill,INK);SetColor(INK);
 FillPoly(3,Pt);
End;

Procedure DrawRuler(X0,X1: Integer; T0: LongInt; PxPerBeat: Integer; Mode: Integer);
{ Mode 1 : arrangement (mesures), 2 : editeurs (temps) }
Var K,X: LongInt; B: LongInt;
Begin
 Box(X0,HD_Y,X1,HD_B,PAPER);
 SetColor(INK);SetLineStyle(SolidLn,0,1);
 Rectangle(X0,HD_Y,X1,HD_B);
 If Mode=1 Then Begin
  K:=0;
  While AR_X0+K*BarPx<=AR_X1 Do Begin
   X:=AR_X0+K*BarPx;
   B:=ViewBar+K+1;
   Line(X,HD_B-6,X,HD_B);
   If (BarPx>=24) Or ((B-1) Mod 4=0) Then PText(X+2,HD_Y+2,IntStr(B));
   Inc(K);
  End;
 End Else Begin
  B:=FloorDiv(T0,BarTicks);
  K:=0;
  While K<200 Do Begin
   X:=X0+((B*BarTicks+K*BeatTicks-T0)*PxPerBeat) Div PPQ;
   If X>X1 Then K:=1000 Else Begin
    If X>=X0 Then Begin
     If (K Mod SigN)=0 Then Begin
      Line(X,HD_Y+1,X,HD_B-1);
      PText(X+2,HD_Y+2,IntStr(B+K Div SigN+1));
     End Else Line(X,HD_B-5,X,HD_B-1);
    End;
    Inc(K);
   End;
  End;
 End;
End;

Procedure DrawArrange;
Var I,Tk,Y,X,K,P,NB: Integer; S: String;
Begin
 S:='ARRANGE - '+ShortName(SongName);
 If Modified Then S:=S+' *';
 DrawTitle(S);
 { parametres }
 PText(6,P1_Y+5,'SNAP');ValBox(46,P1_Y,102,P1_B,SnapLbl[SnapI],False);
 PText(112,P1_Y+5,'MOUSE');ValBox(168,P1_Y,250,P1_B,ToolLbl[ToolI],False);
 PText(262,P1_Y+5,'QUANTIZE');ValBox(340,P1_Y,388,P1_B,QuaLbl[QuaI],False);
 PText(402,P1_Y+5,'CYCLE MODE');ValBox(490,P1_Y,570,P1_B,CycLbl[CycMode],False);
 ArrowBox(580,P1_Y,598,P1_B,3);ArrowBox(602,P1_Y,620,P1_B,4);
 { en-tete }
 Box(0,HD_Y,LW-1,HD_B,PAPER);
 Frame(0,HD_Y,13,HD_B);Frame(14,HD_Y,27,HD_B);
 Frame(28,HD_Y,123,HD_B);Frame(124,HD_Y,195,HD_B);Frame(196,HD_Y,LW-1,HD_B);
 PText(3,HD_Y+3,'M');PText(17,HD_Y+3,'S');
 PText(32,HD_Y+3,'TRACK');PText(128,HD_Y+3,'INSTRUM.');
 PText(199,HD_Y+3,'CHN');
 DrawRuler(AR_X0,AR_X1,0,0,1);
 If FlCycle Then Begin
  SetFillStyle(SolidFill,INK);
  Bar(Integer(Max2(AR_X0,XOfTick(LocL))),HD_B-2,
      Integer(Min2(AR_X1,XOfTick(LocR))),HD_B-1);
 End;
 DrawLocFlag(XOfTick(LocL),'L');
 DrawLocFlag(XOfTick(LocR),'R');
 { pistes }
 For I:=0 To VISR-1 Do Begin
  Tk:=ArrTop+I;
  If Tk<=NTRK Then Begin
   Y:=R0_Y+I*ROWH;
   Box(0,Y,AR_X1,Y+ROWH-1,PAPER);
   SetColor(INK);
   Line(0,Y+ROWH-1,AR_X1,Y+ROWH-1);
   Line(13,Y,13,Y+ROWH-1);Line(27,Y,27,Y+ROWH-1);
   Line(123,Y,123,Y+ROWH-1);Line(195,Y,195,Y+ROWH-1);Line(LW-1,Y,LW-1,Y+ROWH-1);
   If Trk[Tk].Mute Then Begin Box(1,Y+1,12,Y+ROWH-2,INK);WText(3,Y+4,'M');End;
   If Trk[Tk].Solo Then Begin Box(15,Y+1,26,Y+ROWH-2,INK);WText(17,Y+4,'S');End;
   If Tk=CurTrk Then Begin
    Box(29,Y+1,122,Y+ROWH-2,INK);WText(32,Y+4,Copy(Trk[Tk].Name,1,11));
   End Else PText(32,Y+4,Copy(Trk[Tk].Name,1,11));
   PText(127,Y+4,Copy(Trk[Tk].Instr,1,9));
   PText(199,Y+4,PadL(IntStr(Trk[Tk].Chan),2));
   If Trk[Tk].Drum Then PText(214,Y+4,'D');
   { grille des mesures }
   SetLineStyle(UserBitLn,$8888,1);SetColor(INK);
   K:=0;
   While AR_X0+K*BarPx<=AR_X1 Do Begin
    X:=AR_X0+K*BarPx;
    If X>AR_X0 Then Line(X,Y,X,Y+ROWH-2);
    Inc(K);
   End;
   SetLineStyle(SolidLn,0,1);
  End;
 End;
 For P:=1 To MAXPART Do
  If Parts[P].Used Then Begin
   Tk:=Parts[P].Trk;
   If (Tk>=ArrTop) And (Tk<ArrTop+VISR) Then DrawPartBlock(P,TrkY(Tk));
  End;
 SetColor(INK);
 Line(AR_X0,HD_B,AR_X0,R0_B);
 Line(LW-1,R0_Y,LW-1,R0_B);
 { ascenseurs }
 ScrollBarDraw(True,VS_X,R0_Y,SCR_W-1,R0_B,ArrTop-1,NTRK,VISR);
 NB:=1000;
 ScrollBarDraw(False,AR_X0,HS_Y,SCR_W-1,HS_B,ViewBar,NB,VisBars);
 { barre d'information }
 Box(0,HS_Y,LW-1,HS_B,PAPER);Frame(0,HS_Y,LW-1,HS_B);
 P:=FirstSelPart;
 If P>0 Then
  PText(4,HS_Y+4,Copy(Parts[P].Name,1,8)+' '+PosStr(Parts[P].Start)+'>'+
        IntStr(Parts[P].Cnt)+'ev')
 Else PText(4,HS_Y+4,IntStr(PartCount)+' part(s)  '+IntStr(POOL_EV-EvUsed)+' ev');
End;

{ ---- curseur de position / lecture (XOR) ---- }

Function PlayXOf(T: LongInt): Integer;
Forward;

Procedure PlayRange(Var Y1,Y2: Integer);
Forward;

Procedure DrawPlayhead;
Var X,Y1,Y2: Integer;
Begin
 PlayRange(Y1,Y2);
 SetWriteMode(XORPut);
 SetColor(15);SetLineStyle(SolidLn,0,1);
 If PlayX>=0 Then Line(PlayX,Y1,PlayX,Y2);
 PlayX:=-1;
 If Y1>=0 Then Begin
  X:=PlayXOf(CurPos);
  If X>=0 Then Begin
   Line(X,Y1,X,Y2);PlayX:=X;
  End;
 End;
 SetWriteMode(NormalPut);
End;

{ ====================================================================== }
{                       FENETRES D'EDITION D'UNE PARTIE                  }
{ ====================================================================== }

Const
 KX0   = 48;            { debut de la zone des notes }
 KY0   = 68;
 KEYH  = 6;
 KVIS  = 40;
 KY1   = KY0+KVIS*KEYH-1;
 CS_Y  = 328;           { bande de controleurs }
 CS_B  = 396;
 SC_Y0 = 140;           { portee : ligne du haut de la clef de sol }
 DX0   = 76;            { editeur de batterie }
 DROWH = 16;
 GROWH = 13;
 GVIS  = 25;

Type
 TDN = Record
  X,Y,Idx : Integer;
 End;

Var
 DN  : Array[1..400] Of TDN;
 DNN : Integer;

Function EdPx: Integer;
Begin
 EdPx:=EdPxTab[EdZoom];
End;

Function XT(T: LongInt): Integer;
Var V: LongInt;
Begin
 V:=KX0+((T-EdT0)*EdPx) Div PPQ;
 If V<-30000 Then V:=-30000;
 If V>30000 Then V:=30000;
 XT:=Integer(V);
End;

Function TOfX(X: Integer): LongInt;
Begin
 TOfX:=EdT0+((LongInt(X)-KX0)*PPQ) Div EdPx;
End;

Function IsBlack(P: Integer): Boolean;
Var M: Integer;
Begin
 M:=P Mod 12;
 IsBlack:=(M=1) Or (M=3) Or (M=6) Or (M=8) Or (M=10);
End;

Function PY(P: Integer): Integer;
Begin
 PY:=KY0+(EdTop-P)*KEYH;
End;

Function PitchAtY(Y: Integer): Integer;
Begin
 PitchAtY:=EdTop-(Y-KY0) Div KEYH;
End;

Function PartTrk: Integer;
Begin
 If (EdPart>=1) And Parts[EdPart].Used Then PartTrk:=Parts[EdPart].Trk
 Else PartTrk:=CurTrk;
End;

Procedure DrawEdHeader(Const Kind: String);
Var S: String;
Begin
 S:=Kind+' - '+Trk[PartTrk].Name;
 If (EdPart>=1) And Parts[EdPart].Used Then
  S:=S+'   '+PosStr(Parts[EdPart].Start)+' -'+PosStr(Parts[EdPart].Stop);
 DrawTitle(S);
 Button(4,P1_Y,60,P1_B,'KEEP',False,True);
 Button(66,P1_Y,142,P1_B,'CANCEL',False,True);
 PText(152,P1_Y+5,'QUANT');ValBox(200,P1_Y,248,P1_B,QuaLbl[QuaI],False);
 PText(258,P1_Y+5,'MOUSE');ValBox(306,P1_Y,388,P1_B,EdToolLbl[EdToolI],False);
 ArrowBox(580,P1_Y,598,P1_B,3);ArrowBox(602,P1_Y,620,P1_B,4);
End;

{ ---- vue Key Edit ---- }

Function CtlValue(Var E: TEvt; Var V: Integer): Boolean;
Begin
 CtlValue:=False;
 Case CtlKind Of
  0: If E.Kind=EK_NOTE Then Begin V:=E.D2;CtlValue:=True;End;
  1: If E.Kind=EK_BEND Then Begin V:=E.D2;CtlValue:=True;End;
  6: If E.Kind=EK_CHANP Then Begin V:=E.D1;CtlValue:=True;End;
 Else
  If (E.Kind=EK_CTRL) And (E.D1=CtlNum[CtlKind]) Then Begin
   V:=E.D2;CtlValue:=True;End;
 End;
End;

Procedure DrawKeyGrid;
Var R,P,Y,X: Integer; B: LongInt;
Begin
 For R:=0 To KVIS-1 Do Begin
  P:=EdTop-R;
  Y:=KY0+R*KEYH;
  If P>=0 Then Begin
   Box(0,Y,KX0-1,Y+KEYH-1,PAPER);
   If IsBlack(P) Then Begin
    Box(0,Y,27,Y+KEYH-2,INK);
    PatBar(KX0,Y,AR_X1,Y+KEYH-1,PatLight);
   End Else Begin
    SetColor(INK);
    If (P Mod 12=0) Or (P Mod 12=5) Then Line(0,Y+KEYH-1,KX0-1,Y+KEYH-1);
   End;
   If P Mod 12=0 Then Begin
    SetColor(INK);
    Line(KX0,Y+KEYH-1,AR_X1,Y+KEYH-1);
    PText(30,Y-1,NoteName(P));
   End;
  End;
 End;
 SetColor(INK);
 Line(KX0-1,KY0,KX0-1,KY1);
 Line(0,KY1+1,AR_X1,KY1+1);
 { grille }
 B:=FloorDiv(EdT0,BeatTicks)*BeatTicks;
 While XT(B)<=AR_X1 Do Begin
  X:=XT(B);
  If X>=KX0 Then Begin
   If (B Mod BarTicks)=0 Then Begin
    SetLineStyle(SolidLn,0,1);Line(X,KY0,X,KY1);
   End Else Begin
    SetLineStyle(UserBitLn,$AAAA,1);Line(X,KY0,X,KY1);
   End;
  End;
  B:=B+BeatTicks;
 End;
 If (QuaTk[QuaI]>1) And ((QuaTk[QuaI]*EdPx) Div PPQ>=8) Then Begin
  SetLineStyle(UserBitLn,$8888,1);
  B:=FloorDiv(EdT0,QuaTk[QuaI])*QuaTk[QuaI];
  While XT(B)<=AR_X1 Do Begin
   X:=XT(B);
   If (X>=KX0) And ((B Mod BeatTicks)<>0) Then Line(X,KY0,X,KY1);
   B:=B+QuaTk[QuaI];
  End;
 End;
 SetLineStyle(SolidLn,0,1);
End;

Procedure DrawKeyNotes;
Var I,X1,X2,Y,P,V,H,Xs,B: Integer; E: TEvt;
Begin
 P:=EdPart;
 If (P<1) Or (Not Parts[P].Used) Or (Parts[P].Ev=Nil) Then Exit;
 For I:=1 To Parts[P].Cnt Do Begin
  E:=Parts[P].Ev^[I];
  If E.Kind=EK_NOTE Then Begin
   Y:=PY(E.D1);
   If (Y>=KY0) And (Y<=KY1-KEYH+1) Then Begin
    X1:=XT(Parts[P].Start+E.T);
    X2:=XT(Parts[P].Start+E.T+E.Len)-1;
    If X2<X1+2 Then X2:=X1+2;
    If (X2>=KX0) And (X1<=AR_X1) Then Begin
     If X1<KX0 Then X1:=KX0;
     If X2>AR_X1 Then X2:=AR_X1;
     If E.Sel Then Box(X1,Y+1,X2,Y+KEYH-2,INK)
     Else Begin
      Box(X1,Y+1,X2,Y+KEYH-2,PAPER);
      SetColor(INK);Rectangle(X1,Y+1,X2,Y+KEYH-2);
     End;
    End;
   End;
  End;
 End;
 { bande de controleurs }
 Box(0,CS_Y-14,AR_X1,CS_Y-1,PAPER);
 Frame(0,CS_Y-14,AR_X1,CS_Y-1);
 Frame(0,CS_Y,AR_X1,CS_B);
 PText(4,CS_Y-11,'CTRL');
 ValBox(48,CS_Y-14,150,CS_Y-1,CtlLbl[CtlKind],False);
 PText(KX0+4,CS_Y+3,'127');
 SetColor(INK);
 SetLineStyle(UserBitLn,$AAAA,1);
 If CtlKind=0 Then Line(KX0,CS_B-1,AR_X1,CS_B-1)
 Else Line(KX0,(CS_Y+CS_B) Div 2,AR_X1,(CS_Y+CS_B) Div 2);
 SetLineStyle(SolidLn,0,1);
 H:=CS_B-CS_Y-4;
 For I:=1 To Parts[P].Cnt Do Begin
  E:=Parts[P].Ev^[I];
  If CtlValue(E,V) Then Begin
   Xs:=XT(Parts[P].Start+E.T);
   If (Xs>=KX0) And (Xs<=AR_X1) Then Begin
    B:=CS_B-1-(V*H) Div 127;
    If E.Sel Then Begin
     Bar(Xs-1,B,Xs+1,CS_B-1);
    End Else Begin
     Line(Xs,B,Xs,CS_B-1);Line(Xs+1,B,Xs+1,CS_B-1);
    End;
   End;
  End;
 End;
End;

Procedure DrawKeyView;
Begin
 DrawEdHeader('KEY');
 PText(398,P1_Y+5,'LEN');
 ValBox(426,P1_Y,476,P1_B,IntStr(QuaTk[QuaI]),False);
 Box(0,HD_Y,KX0-1,HD_B,PAPER);Frame(0,HD_Y,KX0-1,HD_B);
 PText(4,HD_Y+3,'KEY');
 DrawRuler(KX0,AR_X1,EdT0,EdPx,2);
 DrawKeyGrid;
 DrawKeyNotes;
 ScrollBarDraw(True,VS_X,KY0,SCR_W-1,KY1,127-EdTop,128,KVIS);
 ScrollBarDraw(False,KX0,HS_Y,SCR_W-1,HS_B,EdT0 Div BeatTicks,2000,
               (AR_X1-KX0+1)*PPQ Div EdPx Div BeatTicks);
 Box(0,HS_Y,KX0-1,HS_B,PAPER);Frame(0,HS_Y,KX0-1,HS_B);
End;

{ ---- vue Score Edit ---- }

Function StepOf(P: Integer): Integer;
Const Lt : Array[0..11] Of Byte = (0,0,1,1,2,3,3,4,4,5,5,6);
Begin
 StepOf:=(P Div 12)*7+Lt[P Mod 12];
End;

Function PitchOfStep(S: Integer): Integer;
Const Sm : Array[0..6] Of Byte = (0,2,4,5,7,9,11);
Begin
 If S<0 Then S:=0;
 PitchOfStep:=Integer(Clamp((S Div 7)*12+Sm[S Mod 7],0,127));
End;

Function StepY(S: Integer): Integer;
Begin
 StepY:=SC_Y0+(45-S)*3;
End;

Procedure DrawClef(X,YT,Clef: Integer);
Var YB: Integer;
Begin
 YB:=YT+24;
 SetColor(INK);SetLineStyle(SolidLn,0,1);SetFillStyle(SolidFill,INK);
 Case Clef Of
  1: Begin
      FillEllipse(X+3,YT+6,3,3);
      Ellipse(X+6,YT+7,0,150,7,7);
      Ellipse(X+6,YT+7,0,150,6,7);
      Line(X-1,YT+6,X+4,YT+12);Line(X+4,YT+12,X+8,YT+22);
      FillEllipse(X+14,YT+3,1,1);FillEllipse(X+14,YT+9,1,1);
     End;
  2,3: Begin
      Bar(X,YT,X+2,YB);Line(X+4,YT,X+4,YB);
      If Clef=2 Then Begin
       Ellipse(X+7,YT+6,270,90,5,5);Ellipse(X+7,YT+18,270,90,5,5);
       Line(X+8,YT+10,X+8,YT+14);
      End Else Begin
       Ellipse(X+7,YT+3,270,90,5,5);Ellipse(X+7,YT+9,270,90,5,5);
       Line(X+8,YT+7,X+8,YT+9);
      End;
     End;
 Else
  Begin
   Line(X+5,YT-5,X+5,YB+7);Line(X+6,YT-5,X+6,YB+7);
   Ellipse(X+5,YB-7,0,360,6,6);
   Ellipse(X+5,YT+2,60,360,4,5);
   Arc(X+2,YB+7,180,360,3);
   FillEllipse(X+4,YB-5,1,1);
  End;
 End;
End;

Procedure DrawStaff(Y0: Integer);
Var I: Integer;
Begin
 SetColor(INK);SetLineStyle(SolidLn,0,1);
 For I:=0 To 4 Do Line(8,Y0+I*6,AR_X1,Y0+I*6);
End;

Procedure DrawScoreView;
Var P,I,X,Y,S,Dir,Mid,St,Fl,L,YT,Xb: Integer; E: TEvt; B: LongInt;
 Hollow,Stem: Boolean;
Begin
 DrawEdHeader('SCORE');
 Box(0,HD_Y,KX0-1,HD_B,PAPER);Frame(0,HD_Y,KX0-1,HD_B);
 PText(4,HD_Y+3,'SCORE');
 DrawRuler(KX0,AR_X1,EdT0,EdPx,2);
 DrawStaff(SC_Y0);
 DrawStaff(SC_Y0+36);
 SetColor(INK);
 Line(8,SC_Y0,8,SC_Y0+60);
 DrawClef(14,SC_Y0,0);
 DrawClef(14,SC_Y0+36,1);
 BText(34,SC_Y0+3,IntStr(SigN));BText(34,SC_Y0+15,IntStr(SigD));
 BText(34,SC_Y0+39,IntStr(SigN));BText(34,SC_Y0+51,IntStr(SigD));
 { barres de mesure }
 B:=FloorDiv(EdT0,BarTicks)*BarTicks;
 While XT(B)<=AR_X1 Do Begin
  X:=XT(B);
  If X>=KX0 Then Begin
   SetColor(INK);
   Line(X,SC_Y0,X,SC_Y0+60);
   If (X-KX0)>20 Then PText(X+2,SC_Y0-14,IntStr(B Div BarTicks+1));
  End;
  B:=B+BarTicks;
 End;
 DNN:=0;
 P:=EdPart;
 If (P<1) Or (Not Parts[P].Used) Or (Parts[P].Ev=Nil) Then Exit;
 For I:=1 To Parts[P].Cnt Do Begin
  E:=Parts[P].Ev^[I];
  If E.Kind=EK_NOTE Then Begin
   X:=XT(Parts[P].Start+E.T);
   If (X>=KX0+14) And (X<=AR_X1-6) Then Begin
    St:=StepOf(E.D1);
    Y:=StepY(St);
    SetColor(INK);SetLineStyle(SolidLn,0,1);
    { lignes supplementaires }
    If St>45 Then Begin
     S:=47;
     While S<=St Do Begin Line(X-7,StepY(S),X+7,StepY(S));S:=S+2;End;
    End;
    If St<25 Then Begin
     S:=23;
     While S>=St Do Begin Line(X-7,StepY(S),X+7,StepY(S));S:=S-2;End;
    End;
    If St=35 Then Line(X-7,Y,X+7,Y);
    If E.D1>=60 Then Mid:=41 Else Mid:=29;
    Case E.D1 Mod 12 Of
     1,3,6,8,10: Begin
       Line(X-11,Y-4,X-11,Y+4);Line(X-9,Y-4,X-9,Y+4);
       Line(X-13,Y-1,X-7,Y-1);Line(X-13,Y+2,X-7,Y+2);
      End;
    End;
    Hollow:=(E.Len>=(PPQ*3) Div 2);
    Stem:=(E.Len<PPQ*3);
    SetFillStyle(SolidFill,INK);
    If E.Sel Then Begin
     FillEllipse(X,Y,5,4);Frame(X-8,Y-6,X+8,Y+6);
    End Else If Hollow Then Begin
     Ellipse(X,Y,0,360,4,3);Ellipse(X,Y,0,360,3,2);
    End Else FillEllipse(X,Y,4,3);
    If Stem Then Begin
     If St<Mid Then Begin
      Dir:=-1;Xb:=X+4;
     End Else Begin
      Dir:=1;Xb:=X-4;
     End;
     YT:=Y+Dir*22;
     Line(Xb,Y,Xb,YT);
     If E.Len<(PPQ*3) Div 4 Then Begin
      Fl:=1;
      If E.Len<(PPQ*3) Div 8 Then Fl:=2;
      For L:=1 To Fl Do
       Line(Xb,YT-Dir*(L-1)*4,Xb+6,YT-Dir*(L-1)*4-Dir*8);
     End;
    End;
    If DNN<400 Then Begin
     Inc(DNN);DN[DNN].X:=X;DN[DNN].Y:=Y;DN[DNN].Idx:=I;
    End;
   End;
  End;
 End;
 ScrollBarDraw(False,KX0,HS_Y,SCR_W-1,HS_B,EdT0 Div BeatTicks,2000,
               (AR_X1-KX0+1)*PPQ Div EdPx Div BeatTicks);
 Box(0,HS_Y,KX0-1,HS_B,PAPER);Frame(0,HS_Y,KX0-1,HS_B);
End;

{ ---- vue Grid Edit ---- }

Function EvStatusStr(Var E: TEvt): String;
Begin
 Case E.Kind Of
  EK_NOTE: EvStatusStr:='NOTE';
  EK_CTRL: EvStatusStr:='CONTROL';
  EK_PROG: EvStatusStr:='PRG.CHG';
  EK_BEND: EvStatusStr:='PITCHBEND';
  EK_CHANP: EvStatusStr:='AFTERTCH';
  EK_POLYP: EvStatusStr:='POLY PR.';
 Else EvStatusStr:='?';
 End;
End;

Procedure DrawGridView;
Var P,I,Y,N: Integer; E: TEvt; Inv: Boolean; S1,S2,S3: String;
Begin
 DrawEdHeader('GRID');
 Box(0,HD_Y,SCR_W-1,HD_B,PAPER);Frame(0,HD_Y,SCR_W-1,HD_B);
 PText(8,HD_Y+3,'START');PText(120,HD_Y+3,'LENGTH');PText(190,HD_Y+3,'STATUS');
 PText(290,HD_Y+3,'DATA 1');PText(380,HD_Y+3,'DATA 2');PText(460,HD_Y+3,'CHN');
 P:=EdPart;
 If (P<1) Or (Not Parts[P].Used) Then Exit;
 N:=Parts[P].Cnt;
 For I:=0 To GVIS-1 Do Begin
  Y:=R0_Y+I*GROWH;
  If ListTop+I<=N Then Begin
   E:=Parts[P].Ev^[ListTop+I];
   Inv:=E.Sel Or (ListTop+I=ListSel);
   If Inv Then Box(0,Y,VS_X-1,Y+GROWH-1,INK);
   If E.Kind=EK_NOTE Then Begin S1:=NoteName(E.D1)+' ('+IntStr(E.D1)+')';S2:=IntStr(E.D2);
    S3:=IntStr(E.Len);End
   Else Begin S1:=IntStr(E.D1);S2:=IntStr(E.D2);S3:='';End;
   If Inv Then Begin
    WText(8,Y+3,PosStr(Parts[P].Start+E.T));WText(120,Y+3,S3);
    WText(190,Y+3,EvStatusStr(E));WText(290,Y+3,S1);WText(380,Y+3,S2);
    WText(460,Y+3,IntStr(Trk[Parts[P].Trk].Chan));
   End Else Begin
    PText(8,Y+3,PosStr(Parts[P].Start+E.T));PText(120,Y+3,S3);
    PText(190,Y+3,EvStatusStr(E));PText(290,Y+3,S1);PText(380,Y+3,S2);
    PText(460,Y+3,IntStr(Trk[Parts[P].Trk].Chan));
   End;
  End;
 End;
 ScrollBarDraw(True,VS_X,R0_Y,SCR_W-1,R0_Y+GVIS*GROWH-1,ListTop-1,
               Max2(N,GVIS),GVIS);
 Box(0,HS_Y,SCR_W-1,HS_B,PAPER);Frame(0,HS_Y,SCR_W-1,HS_B);
 PText(8,HS_Y+4,IntStr(N)+' events');
End;

{ ---- vue Drum Edit ---- }

Function DXOf(T: LongInt): Integer;
Var V: LongInt;
Begin
 V:=DX0+((T-EdT0)*EdPx) Div PPQ;
 If V<-30000 Then V:=-30000;
 If V>30000 Then V:=30000;
 DXOf:=Integer(V);
End;

Procedure DrawDrumView;
Var R,Y,I,P,X,Sz,L,K: Integer; E: TEvt; B: LongInt;
Begin
 DrawEdHeader('DRUM');
 PText(398,P1_Y+5,'VEL');
 For K:=1 To 4 Do
  ValBox(426+(K-1)*38,P1_Y,460+(K-1)*38,P1_B,IntStr(DrumVel[K]),K=DrumVelI);
 Box(0,HD_Y,DX0-1,HD_B,PAPER);Frame(0,HD_Y,DX0-1,HD_B);
 PText(4,HD_Y+3,'DRUM');
 DrawRuler(DX0,AR_X1,EdT0,EdPx,2);
 For R:=1 To NDRUM Do Begin
  Y:=KY0+(R-1)*DROWH;
  Box(0,Y,DX0-1,Y+DROWH-1,PAPER);
  Frame(0,Y,DX0-1,Y+DROWH-1);
  PText(4,Y+4,Copy(DrumNm[R],1,8));
  If R Mod 2=0 Then PatBar(DX0,Y,AR_X1,Y+DROWH-1,PatLight);
  SetColor(INK);SetLineStyle(SolidLn,0,1);
  Line(DX0,Y+DROWH-1,AR_X1,Y+DROWH-1);
 End;
 { grille }
 L:=QuaTk[QuaI];If L<=1 Then L:=PPQ Div 4;
 B:=FloorDiv(EdT0,L)*L;
 While DXOf(B)<=AR_X1 Do Begin
  X:=DXOf(B);
  If X>=DX0 Then Begin
   If (B Mod BarTicks)=0 Then SetLineStyle(SolidLn,0,1)
   Else If (B Mod BeatTicks)=0 Then SetLineStyle(UserBitLn,$AAAA,1)
   Else SetLineStyle(UserBitLn,$8888,1);
   SetColor(INK);
   Line(X,KY0,X,KY0+NDRUM*DROWH-1);
  End;
  B:=B+L;
 End;
 SetLineStyle(SolidLn,0,1);
 P:=EdPart;
 If (P>=1) And Parts[P].Used And (Parts[P].Ev<>Nil) Then
  For I:=1 To Parts[P].Cnt Do Begin
   E:=Parts[P].Ev^[I];
   If E.Kind=EK_NOTE Then
    For R:=1 To NDRUM Do
     If DrumNote[R]=E.D1 Then Begin
      X:=DXOf(Parts[P].Start+E.T);
      If (X>=DX0) And (X<=AR_X1) Then Begin
       Y:=KY0+(R-1)*DROWH+DROWH Div 2;
       If E.D2>=DrumVel[4] Then Sz:=6
       Else If E.D2>=DrumVel[3] Then Sz:=5
       Else If E.D2>=DrumVel[2] Then Sz:=4 Else Sz:=3;
       SetColor(INK);SetFillStyle(SolidFill,INK);
       Bar(X-Sz+2,Y-Sz,X+Sz+2,Y+Sz);
       If E.D2<DrumVel[2] Then Begin
        Box(X-Sz+3,Y-Sz+1,X+Sz+1,Y+Sz-1,PAPER);
       End;
      End;
     End;
  End;
 SetColor(INK);
 Line(DX0-1,KY0,DX0-1,KY0+NDRUM*DROWH-1);
 ScrollBarDraw(False,DX0,HS_Y,SCR_W-1,HS_B,EdT0 Div BeatTicks,2000,
               (AR_X1-DX0+1)*PPQ Div EdPx Div BeatTicks);
 Box(0,HS_Y,DX0-1,HS_B,PAPER);Frame(0,HS_Y,DX0-1,HS_B);
End;

{ ---- piste maitre (tempo) ---- }

Const
 MG_Y0 = 70;
 MG_Y1 = 220;
 ML_Y  = 244;
 MROWH = 12;
 MVIS  = 12;

Function MstX(T: LongInt): Integer;
Var V: LongInt;
Begin
 V:=48+((T-EdT0)*EdPx) Div PPQ;
 If V<-30000 Then V:=-30000;
 If V>30000 Then V:=30000;
 MstX:=Integer(V);
End;

Procedure DrawMasterView;
Var I,X,Y,LastY,LastX: Integer; Inv: Boolean;
 TMin,TMax: Integer;
Begin
 DrawTitle('MASTER TRACK - TEMPO');
 PText(6,P1_Y+5,'MASTER');
 ValBox(60,P1_Y,100,P1_B,'',False);
 If FlMaster Then BText(66,P1_Y+5,'ON') Else BText(66,P1_Y+5,'OFF');
 PText(112,P1_Y+5,'TEMPO');ValBox(164,P1_Y,220,P1_B,TempoStr(TempoFix),False);
 PText(232,P1_Y+5,'SIGN');ValBox(272,P1_Y,320,P1_B,IntStr(SigN)+'/'+IntStr(SigD),False);
 Button(334,P1_Y,414,P1_B,'INSERT',False,True);
 Button(420,P1_Y,500,P1_B,'DELETE',False,True);
 Button(506,P1_Y,576,P1_B,'EXIT',False,True);
 ArrowBox(580,P1_Y,598,P1_B,3);ArrowBox(602,P1_Y,620,P1_B,4);
 DrawRuler(48,AR_X1,EdT0,EdPx,2);
 Box(0,HD_Y,47,HD_B,PAPER);Frame(0,HD_Y,47,HD_B);PText(4,HD_Y+3,'BPM');
 { courbe }
 Frame(0,MG_Y0,AR_X1,MG_Y1);
 TMin:=TempoFix;TMax:=TempoFix;
 For I:=1 To NTemp Do Begin
  If Tempos[I].V<TMin Then TMin:=Tempos[I].V;
  If Tempos[I].V>TMax Then TMax:=Tempos[I].V;
 End;
 TMin:=(TMin Div 100)*100-100;TMax:=(TMax Div 100)*100+200;
 If TMin<0 Then TMin:=0;
 SetColor(INK);
 PText(4,MG_Y0+2,IntStr(TMax Div 10));PText(4,MG_Y1-10,IntStr(TMin Div 10));
 If (FlMaster) And (NTemp>0) Then Begin
  LastX:=48;LastY:=MG_Y1-1-Integer((LongInt(Tempos[1].V-TMin)*(MG_Y1-MG_Y0-2)) Div (TMax-TMin));
  For I:=1 To NTemp Do Begin
   X:=MstX(Tempos[I].T);
   Y:=MG_Y1-1-Integer((LongInt(Tempos[I].V-TMin)*(MG_Y1-MG_Y0-2)) Div (TMax-TMin));
   If X<48 Then X:=48;
   If X>AR_X1 Then X:=AR_X1;
   Line(LastX,LastY,X,LastY);Line(X,LastY,X,Y);
   LastX:=X;LastY:=Y;
   FillEllipse(X,Y,2,2);
  End;
  Line(LastX,LastY,AR_X1,LastY);
 End Else Begin
  Y:=MG_Y1-1-Integer((LongInt(TempoFix-TMin)*(MG_Y1-MG_Y0-2)) Div (TMax-TMin));
  SetLineStyle(UserBitLn,$AAAA,1);Line(48,Y,AR_X1,Y);SetLineStyle(SolidLn,0,1);
 End;
 { liste }
 Box(0,ML_Y-14,AR_X1,ML_Y-1,PAPER);Frame(0,ML_Y-14,AR_X1,ML_Y-1);
 PText(8,ML_Y-11,'START');PText(120,ML_Y-11,'TEMPO');PText(200,ML_Y-11,'BPM');
 For I:=0 To MVIS-1 Do Begin
  Y:=ML_Y+I*MROWH;
  If MstTop+I<=NTemp Then Begin
   Inv:=(MstTop+I=MstSel);
   If Inv Then Box(0,Y,AR_X1,Y+MROWH-1,INK);
   If Inv Then Begin
    WText(8,Y+2,PosStr(Tempos[MstTop+I].T));
    WText(120,Y+2,IntStr(Tempos[MstTop+I].V));
    WText(200,Y+2,TempoStr(Tempos[MstTop+I].V));
   End Else Begin
    PText(8,Y+2,PosStr(Tempos[MstTop+I].T));
    PText(120,Y+2,IntStr(Tempos[MstTop+I].V));
    PText(200,Y+2,TempoStr(Tempos[MstTop+I].V));
   End;
  End;
 End;
 ScrollBarDraw(True,VS_X,ML_Y,SCR_W-1,ML_Y+MVIS*MROWH-1,MstTop-1,
               Max2(NTemp,MVIS),MVIS);
 ScrollBarDraw(False,48,HS_Y,SCR_W-1,HS_B,EdT0 Div BeatTicks,2000,
               (AR_X1-48+1)*PPQ Div EdPx Div BeatTicks);
End;

{ ====================================================================== }
{                          DESSIN GLOBAL                                 }
{ ====================================================================== }

Procedure DrawMenuBar;
Forward;

Procedure DrawDropDown;
Forward;

Function PlayXOf(T: LongInt): Integer;
Var X: Integer;
Begin
 PlayXOf:=-1;
 Case View Of
  V_ARR: Begin X:=XOfTick(T);If (X>=AR_X0) And (X<=AR_X1) Then PlayXOf:=X;End;
  V_KEY,V_SCORE: Begin X:=XT(T);If (X>=KX0) And (X<=AR_X1) Then PlayXOf:=X;End;
  V_DRUM: Begin X:=DXOf(T);
            If (X>=DX0) And (X<=AR_X1) Then PlayXOf:=X;End;
 End;
End;

Procedure PlayRange(Var Y1,Y2: Integer);
Begin
 Y1:=-1;Y2:=-1;
 Case View Of
  V_ARR: Begin Y1:=HD_B+1;Y2:=R0_B;End;
  V_KEY: Begin Y1:=KY0;Y2:=CS_B;End;
  V_SCORE: Begin Y1:=HD_B+1;Y2:=HS_Y-2;End;
  V_DRUM: Begin Y1:=KY0;Y2:=KY0+NDRUM*DROWH-1;End;
 End;
End;

Procedure DrawAll;
Begin
 HideMouse;
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 Box(0,0,SCR_W-1,SCR_H-1,PAPER);
 Case View Of
  V_ARR: DrawArrange;
  V_KEY: DrawKeyView;
  V_SCORE: DrawScoreView;
  V_GRID: DrawGridView;
  V_DRUM: DrawDrumView;
  V_MASTER: DrawMasterView;
 End;
 DrawTransport;
 DrawMenuBar;
 DrawDropDown;
 PlayX:=-1;
 DrawPlayhead;
 ShowMouse;
 NeedDraw:=False;
End;

Procedure UpdatePlayDisplay;
Var X: Integer;
Begin
 If Not Playing Then Exit;
 If (PlayShown>=0) And (Abs(PlayTick-PlayShown)<PPQ Div 4) Then Exit;
 If FlFollow And (PlayTick>=0) And (View<>V_GRID) And (View<>V_MASTER) Then Begin
  X:=PlayXOf(PlayTick);
  If View=V_ARR Then Begin
   If (X<0) Then Begin ViewBar:=FloorDiv(PlayTick,BarTicks);NeedDraw:=True;Exit;End;
  End Else If X<0 Then Begin
   EdT0:=FloorDiv(PlayTick,BarTicks)*BarTicks;NeedDraw:=True;Exit;
  End;
 End;
 HideMouse;
 DrawPosCells;
 DrawPlayhead;
 ShowMouse;
End;

{ ====================================================================== }
{                  FICHIERS : ARRANGEMENT (.ARR) ET MIDI (.MID)          }
{ ====================================================================== }

Function B2B(V: Boolean): Byte;
Begin
 If V Then B2B:=1 Else B2B:=0;
End;

Function SaveArr(Const Name: String): Boolean;
Var F: File; H: TSonHdr; I: Integer; PH: TPartHdr;
Begin
 SaveArr:=False;
 FillChar(H,SizeOf(H),0);
 H.ID:='CUBA';H.Ver:=1;H.Tempo:=TempoFix;H.LocL:=LocL;H.LocR:=LocR;
 H.SigN:=SigN;H.SigD:=SigD;
 H.Flags[1]:=B2B(FlMaster);H.Flags[2]:=B2B(FlCycle);H.Flags[3]:=B2B(FlPunch);
 H.Flags[4]:=B2B(FlClick);H.Flags[5]:=B2B(FlOverdub);H.Flags[6]:=B2B(FlChase);
 H.Flags[7]:=B2B(FlFollow);H.Flags[8]:=B2B(FlReset);H.Flags[9]:=B2B(FlTempoRec);
 H.Flags[10]:=B2B(FlThru);H.Flags[11]:=SnapI;H.Flags[12]:=QuaI;
 H.Flags[13]:=ZoomI;H.Flags[14]:=CycMode;
 H.NP:=PartCount;H.NT:=NTemp;
 {$I-}
 Assign(F,Name);
 Rewrite(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 {$I-}
 BlockWrite(F,H,SizeOf(H));
 BlockWrite(F,ArrPP,SizeOf(ArrPP));
 BlockWrite(F,Trk,SizeOf(Trk));
 BlockWrite(F,Tempos,SizeOf(Tempos));
 BlockWrite(F,DrumNote,SizeOf(DrumNote));
 BlockWrite(F,DrumNm,SizeOf(DrumNm));
 For I:=1 To MAXPART Do
  If Parts[I].Used Then Begin
   PH.Trk:=Parts[I].Trk;PH.Name:=Parts[I].Name;PH.Start:=Parts[I].Start;
   PH.Stop:=Parts[I].Stop;PH.Cnt:=Parts[I].Cnt;PH.Mute:=Parts[I].Mute;
   PH.PP:=Parts[I].PP;
   BlockWrite(F,PH,SizeOf(PH));
   If PH.Cnt>0 Then BlockWrite(F,Parts[I].Ev^,PH.Cnt*SizeOf(TEvt));
  End;
 Close(F);
 {$I+}
 SaveArr:=(IOResult=0);
End;

Function LoadArr(Const Name: String; ForUndo: Boolean): Boolean;
Var F: File; H: TSonHdr; I,K,P: Integer; PH: TPartHdr; N: Word; Ok: Boolean;
 SN: String[79]; SNm: Boolean; ST,SA,SV: Integer; SB: LongInt;
Begin
 LoadArr:=False;
 {$I-}
 Assign(F,Name);
 Reset(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 {$I-}
 BlockRead(F,H,SizeOf(H),N);
 {$I+}
 If (N<>SizeOf(H)) Or (H.ID<>'CUBA') Then Begin Close(F);Exit;End;
 SN:=SongName;SNm:=SongNamed;ST:=CurTrk;SA:=ArrTop;SB:=ViewBar;
 SV:=View;
 InitSong;
 TempoFix:=H.Tempo;LocL:=H.LocL;LocR:=H.LocR;SigN:=H.SigN;SigD:=H.SigD;
 If (SigN<1) Or (SigD<1) Then Begin SigN:=4;SigD:=4;End;
 If (TempoFix<20) Or (TempoFix>3000) Then TempoFix:=1200;
 FlMaster:=H.Flags[1]=1;FlCycle:=H.Flags[2]=1;FlPunch:=H.Flags[3]=1;
 FlClick:=H.Flags[4]=1;FlOverdub:=H.Flags[5]=1;FlChase:=H.Flags[6]=1;
 FlFollow:=H.Flags[7]=1;FlReset:=H.Flags[8]=1;FlTempoRec:=H.Flags[9]=1;
 FlThru:=H.Flags[10]=1;
 SnapI:=H.Flags[11] Mod NSNAP;QuaI:=H.Flags[12] Mod (NQUA+1);
 ZoomI:=H.Flags[13];If (ZoomI<1) Or (ZoomI>6) Then ZoomI:=3;
 CycMode:=H.Flags[14] Mod 3;
 Ok:=True;
 {$I-}
 BlockRead(F,ArrPP,SizeOf(ArrPP),N);
 BlockRead(F,Trk,SizeOf(Trk),N);
 BlockRead(F,Tempos,SizeOf(Tempos),N);
 BlockRead(F,DrumNote,SizeOf(DrumNote),N);
 BlockRead(F,DrumNm,SizeOf(DrumNm),N);
 {$I+}
 NTemp:=H.NT;
 If NTemp>NTEMPO Then NTemp:=NTEMPO;
 For K:=1 To H.NP Do
  If Ok Then Begin
   {$I-}
   BlockRead(F,PH,SizeOf(PH),N);
   {$I+}
   If N<>SizeOf(PH) Then Ok:=False Else Begin
    If (PH.Trk<1) Or (PH.Trk>NTRK) Then PH.Trk:=1;
    P:=PartNew(PH.Trk,PH.Start,PH.Stop,PH.Name);
    If P=0 Then Ok:=False Else Begin
     Parts[P].Mute:=PH.Mute;Parts[P].PP:=PH.PP;
     If PH.Cnt>MAXEV Then PH.Cnt:=MAXEV;
     If PH.Cnt>0 Then Begin
      Parts[P].Cap:=0;
      While Parts[P].Cap<PH.Cnt Do
       If Not PartGrow(P) Then Begin Ok:=False;PH.Cnt:=0;Parts[P].Cap:=MAXEV+1;End;
      If Ok Then Begin
       {$I-}
       BlockRead(F,Parts[P].Ev^,PH.Cnt*SizeOf(TEvt),N);
       {$I+}
       Parts[P].Cnt:=PH.Cnt;Inc(EvUsed,PH.Cnt);
       For I:=1 To PH.Cnt Do Parts[P].Ev^[I].Sel:=False;
      End;
     End;
    End;
   End;
  End;
 Close(F);
 If ForUndo Then Begin
  SongName:=SN;SongNamed:=SNm;Modified:=True;CurTrk:=ST;ArrTop:=SA;
  ViewBar:=SB;View:=SV;
 End Else Begin
  SongName:=Name;
  If Length(Name)>79 Then SongName:=ShortName(Name);
  SongNamed:=True;Modified:=False;
 End;
 LoadArr:=Ok;
End;

Procedure SaveUndo;
Begin
 UndoValid:=SaveArr(UNDOFILE);
End;

Procedure DoUndo;
Begin
 If Not UndoValid Then Begin
  Info('Nothing to undo.','Rien '#133' annuler.','Nichts r'#129'ckg'#132'ngig zu machen.');
  Exit;
 End;
 If Playing Then StopPlay;
 If LoadArr(UNDOFILE,True) Then Begin
  UndoValid:=False;
  If View<>V_ARR Then View:=V_ARR;
  EdPart:=0;
 End;
 NeedDraw:=True;
End;

{ ---- Standard MIDI File : ecriture ---- }

Var
 MBuf : PByteArr;
 MLen : Integer;
 Msg  : PMsgArr;

Procedure MPut(B: Integer);
Begin
 If MLen<16000 Then Begin MBuf^[MLen]:=B And $FF;Inc(MLen);End;
End;

Procedure MPutVLQ(V: LongInt);
Var Tmp: Array[1..5] Of Byte; N,I: Integer;
Begin
 N:=1;Tmp[1]:=V And $7F;V:=V Shr 7;
 While V>0 Do Begin Inc(N);Tmp[N]:=(V And $7F) Or $80;V:=V Shr 7;End;
 For I:=N DownTo 1 Do MPut(Tmp[I]);
End;

Procedure PutBE(Var F: File; V: LongInt; N: Integer);
Var I: Integer; B: Byte;
Begin
 For I:=N-1 DownTo 0 Do Begin
  B:=(V Shr (I*8)) And $FF;
  BlockWrite(F,B,1);
 End;
End;

Procedure FlushTrack(Var F: File);
Var S: String[4];
Begin
 S:='MTrk';
 BlockWrite(F,S[1],4);
 PutBE(F,MLen,4);
 BlockWrite(F,MBuf^,MLen);
 MLen:=0;
End;

Procedure MPutText(Ty: Integer; Const S: String);
Var I: Integer;
Begin
 MPut($FF);MPut(Ty);MPutVLQ(Length(S));
 For I:=1 To Length(S) Do MPut(Ord(S[I]));
End;

Function Log2(V: Integer): Integer;
Var N: Integer;
Begin
 N:=0;
 While V>1 Do Begin V:=V Shr 1;Inc(N);End;
 Log2:=N;
End;


Var
 RF     : File;
 RBuf   : Array[0..1023] Of Byte;
 RPos,RLen : Integer;
 RCount : LongInt;
 REof   : Boolean;

Function RdB: Integer;
Var W: Word;
Begin
 If RPos>=RLen Then Begin
  {$I-}
  BlockRead(RF,RBuf,1024,W);
  {$I+}
  If IOResult<>0 Then W:=0;
  RLen:=W;RPos:=0;
  If W=0 Then Begin REof:=True;RdB:=0;Exit;End;
 End;
 RdB:=RBuf[RPos];Inc(RPos);Inc(RCount);
End;

Function RdBE(N: Integer): LongInt;
Var V: LongInt; I: Integer;
Begin
 V:=0;
 For I:=1 To N Do V:=V*256+RdB;
 RdBE:=V;
End;

Function RdVLQ: LongInt;
Var V: LongInt; B,N: Integer;
Begin
 V:=0;N:=0;
 Repeat
  B:=RdB;V:=V*128+(B And $7F);Inc(N);
 Until ((B And $80)=0) Or (N>=5) Or REof;
 RdVLQ:=V;
End;

Function SaveMidi(Const Name: String): Boolean;
Var F: File; NT,T,I,J,K,M,P: Integer; US,Last: LongInt; Ch: Byte;
 X: TMsg; S: String[4]; Used: Array[1..NTRK] Of Boolean;
 Tm: LongInt;

 Procedure Push(Tt: LongInt; O,St,D1,D2,C: Integer);
 Begin
  If M<2398 Then Begin
   Inc(M);Msg^[M].T:=Tt;Msg^[M].Ord1:=O;Msg^[M].S:=St;Msg^[M].D1:=D1;
   Msg^[M].D2:=D2;Msg^[M].Cnt:=C;
  End;
 End;

Begin
 SaveMidi:=False;
 NT:=0;
 FillChar(Used,SizeOf(Used),0);
 For I:=1 To MAXPART Do
  If Parts[I].Used And (Parts[I].Cnt>0) Then Used[Parts[I].Trk]:=True;
 For T:=1 To NTRK Do If Used[T] Then Inc(NT);
 If MBuf=Nil Then New(MBuf);
 If Msg=Nil Then New(Msg);
 {$I-}
 Assign(F,Name);
 Rewrite(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 S:='MThd';BlockWrite(F,S[1],4);
 PutBE(F,6,4);PutBE(F,1,2);PutBE(F,NT+1,2);PutBE(F,PPQ,2);
 { piste 0 : tempo et mesure }
 MLen:=0;
 MPut(0);MPutText(3,ShortName(SongName));
 Last:=0;
 If FlMaster And (NTemp>0) Then Begin
  For K:=1 To NTemp Do Begin
   US:=Round(6.0E8/Tempos[K].V);
   MPutVLQ(Tempos[K].T-Last);Last:=Tempos[K].T;
   MPut($FF);MPut($51);MPut(3);
   MPut((US Shr 16) And $FF);MPut((US Shr 8) And $FF);MPut(US And $FF);
  End;
 End Else Begin
  US:=Round(6.0E8/TempoFix);
  MPut(0);MPut($FF);MPut($51);MPut(3);
  MPut((US Shr 16) And $FF);MPut((US Shr 8) And $FF);MPut(US And $FF);
 End;
 MPut(0);MPut($FF);MPut($58);MPut(4);MPut(SigN);MPut(Log2(SigD));MPut(24);MPut(8);
 MPut(0);MPut($FF);MPut($2F);MPut(0);
 FlushTrack(F);
 For T:=1 To NTRK Do
  If Used[T] Then Begin
   Ch:=Trk[T].Chan-1;
   M:=0;
   For P:=1 To MAXPART Do
    If Parts[P].Used And (Parts[P].Trk=T) And (Parts[P].Ev<>Nil) Then
     For I:=1 To Parts[P].Cnt Do Begin
      Tm:=Parts[P].Start+Parts[P].Ev^[I].T;
      Case Parts[P].Ev^[I].Kind Of
       EK_NOTE: Begin
         Push(Tm+Parts[P].Ev^[I].Len,0,$80+Ch,Parts[P].Ev^[I].D1,0,3);
         Push(Tm,1,$90+Ch,Parts[P].Ev^[I].D1,Parts[P].Ev^[I].D2,3);
        End;
       EK_CTRL: Push(Tm,1,$B0+Ch,Parts[P].Ev^[I].D1,Parts[P].Ev^[I].D2,3);
       EK_BEND: Push(Tm,1,$E0+Ch,Parts[P].Ev^[I].D1,Parts[P].Ev^[I].D2,3);
       EK_POLYP: Push(Tm,1,$A0+Ch,Parts[P].Ev^[I].D1,Parts[P].Ev^[I].D2,3);
       EK_PROG: Push(Tm,1,$C0+Ch,Parts[P].Ev^[I].D1,0,2);
       EK_CHANP: Push(Tm,1,$D0+Ch,Parts[P].Ev^[I].D1,0,2);
      End;
     End;
   For I:=2 To M Do Begin
    X:=Msg^[I];J:=I-1;
    While (J>=1) And ((Msg^[J].T>X.T) Or ((Msg^[J].T=X.T) And (Msg^[J].Ord1>X.Ord1))) Do Begin
     Msg^[J+1]:=Msg^[J];Dec(J);End;
    Msg^[J+1]:=X;
   End;
   MLen:=0;
   MPut(0);MPutText(3,Trk[T].Name);
   K:=ProgOf(Trk[T].Instr);
   If (Not Trk[T].Drum) And (K>=0) Then Begin MPut(0);MPut($C0+Ch);MPut(K);End;
   Last:=0;
   For I:=1 To M Do Begin
    MPutVLQ(Msg^[I].T-Last);Last:=Msg^[I].T;
    MPut(Msg^[I].S);MPut(Msg^[I].D1);
    If Msg^[I].Cnt=3 Then MPut(Msg^[I].D2);
   End;
   MPut(0);MPut($FF);MPut($2F);MPut(0);
   FlushTrack(F);
  End;
 Close(F);
 SaveMidi:=(IOResult=0);
End;

{ ---- Standard MIDI File : lecture ---- }

Function LoadMidi(Const Name: String): Boolean;
Var Fmt,NTrkM,FPPQ,TrkN,K,I,B,St,Run,Ty,Ch,D1,D2,Slot,NSlot,Pend: Integer;
 Len,CEnd,Abs,Tm,US,MaxT: LongInt; S: String; Ok,GotTempo: Boolean;
 Hold: String[12]; Id: String[4]; Fnd: Boolean; P: Integer;
 SlotTrk,SlotCh,SlotPart,Prog: Array[1..NTRK] Of Integer;
 NTm: Integer;

 Function SlotOf(MT,C: Integer): Integer;
 Var J,Pi: Integer;
 Begin
  SlotOf:=0;
  For J:=1 To NSlot Do
   If (SlotTrk[J]=MT) And (SlotCh[J]=C) Then Begin SlotOf:=J;Exit;End;
  If NSlot<NTRK Then Begin
   Inc(NSlot);SlotTrk[NSlot]:=MT;SlotCh[NSlot]:=C;Prog[NSlot]:=-1;
   ResetTrack(NSlot);
   Trk[NSlot].Chan:=C+1;Trk[NSlot].Drum:=(C=9);
   If C=9 Then Trk[NSlot].Instr:='Drums' Else Trk[NSlot].Instr:='';
   If Hold<>'' Then Trk[NSlot].Name:=Copy(Hold,1,12);
   Pi:=PartNew(NSlot,0,BarTicks,Trk[NSlot].Name);
   SlotPart[NSlot]:=Pi;
   SlotOf:=NSlot;
  End;
 End;

Begin
 LoadMidi:=False;
 {$I-}
 Assign(RF,Name);
 Reset(RF,1);
 {$I+}
 If IOResult<>0 Then Exit;
 RPos:=0;RLen:=0;REof:=False;RCount:=0;
 Id:='';
 For I:=1 To 4 Do Id:=Id+Chr(RdB);
 If Id<>'MThd' Then Begin Close(RF);Exit;End;
 Len:=RdBE(4);Fmt:=RdBE(2);NTrkM:=RdBE(2);FPPQ:=RdBE(2);
 For I:=7 To Len Do B:=RdB;
 If FPPQ<=0 Then Begin Close(RF);Exit;End;
 If Fmt<0 Then Fmt:=0;
 InitSong;
 NSlot:=0;GotTempo:=False;MaxT:=0;Ok:=True;NTm:=0;
 For TrkN:=1 To NTrkM Do
  If Ok And Not REof Then Begin
   Id:='';
   For I:=1 To 4 Do Id:=Id+Chr(RdB);
   Len:=RdBE(4);
   If Id<>'MTrk' Then Begin
    For K:=1 To Len Do B:=RdB;
   End Else Begin
    RCount:=0;Abs:=0;Run:=0;Pend:=-1;Hold:='';
    While (RCount<Len) And Not REof Do Begin
     Abs:=Abs+RdVLQ;
     Tm:=(Abs*PPQ) Div FPPQ;
     B:=RdB;
     If B>=$80 Then Begin St:=B;If St<$F0 Then Run:=St;End
     Else Begin St:=Run;Pend:=B;End;
     If St=$FF Then Begin
      Ty:=RdB;CEnd:=RdVLQ;S:='';
      For K:=1 To CEnd Do Begin
       B:=RdB;
       If Length(S)<20 Then S:=S+Chr(B);
      End;
      Case Ty Of
       3: Hold:=Copy(S,1,12);
       $51: If Length(S)=3 Then Begin
             US:=Ord(S[1])*65536+Ord(S[2])*256+Ord(S[3]);
             If US>0 Then Begin
              If Not GotTempo Then Begin TempoFix:=Integer(Clamp(Round(6.0E8/US),20,3000));GotTempo:=True;End;
              If NTm<NTEMPO Then Begin
               Inc(NTm);
               TempoSet(Tm,Integer(Clamp(Round(6.0E8/US),20,3000)));
              End;
             End;
            End;
       $58: If Length(S)>=2 Then Begin
             SigN:=Ord(S[1]);SigD:=1 Shl Ord(S[2]);
             If (SigN<1) Or (SigD<1) Or (SigD>32) Then Begin SigN:=4;SigD:=4;End;
            End;
      End;
     End Else If (St=$F0) Or (St=$F7) Then Begin
      CEnd:=RdVLQ;
      For K:=1 To CEnd Do B:=RdB;
     End Else Begin
      Ch:=St And 15;
      If Pend>=0 Then Begin D1:=Pend;Pend:=-1;End Else D1:=RdB;
      D2:=0;
      If ((St And $F0)<>$C0) And ((St And $F0)<>$D0) Then D2:=RdB;
      Slot:=SlotOf(TrkN,Ch);
      If Slot>0 Then Begin
       P:=SlotPart[Slot];
       If P>0 Then Begin
        Case St Shr 4 Of
         9: If D2>0 Then EvAdd(P,Tm,0,EK_NOTE,D1,D2);
         11: EvAdd(P,Tm,0,EK_CTRL,D1,D2);
         12: Begin EvAdd(P,Tm,0,EK_PROG,D1,0);If Prog[Slot]<0 Then Prog[Slot]:=D1;End;
         13: EvAdd(P,Tm,0,EK_CHANP,D1,0);
         14: EvAdd(P,Tm,0,EK_BEND,D1,D2);
         10: EvAdd(P,Tm,0,EK_POLYP,D1,D2);
        End;
        If ((St Shr 4)=8) Or (((St Shr 4)=9) And (D2=0)) Then Begin
         K:=Parts[P].Cnt;Fnd:=False;
         While (K>=1) And Not Fnd Do Begin
          If (Parts[P].Ev^[K].Kind=EK_NOTE) And (Parts[P].Ev^[K].D1=D1) And
             (Parts[P].Ev^[K].Len=0) Then Begin
           Parts[P].Ev^[K].Len:=Tm-Parts[P].Ev^[K].T;
           If Parts[P].Ev^[K].Len<1 Then Parts[P].Ev^[K].Len:=1;
           Fnd:=True;
          End;
          Dec(K);
         End;
        End;
        If Tm>MaxT Then MaxT:=Tm;
       End;
      End;
     End;
    End;
   End;
  End;
 Close(RF);
 For I:=1 To NSlot Do Begin
  P:=SlotPart[I];
  If P>0 Then Begin
   For K:=1 To Parts[P].Cnt Do
    If (Parts[P].Ev^[K].Kind=EK_NOTE) And (Parts[P].Ev^[K].Len=0) Then
     Parts[P].Ev^[K].Len:=PPQ Div 4;
   Parts[P].Stop:=(FloorDiv(MaxT+PPQ,BarTicks)+1)*BarTicks;
   If (Trk[I].Instr='') And (Prog[I]>=0) Then
    For K:=1 To NINST Do If (InstProg[K]=Prog[I]) And (K<NINST) Then
      Trk[I].Instr:=InstName[K];
   If Parts[P].Cnt=0 Then PartFree(P);
  End;
 End;
 If NTemp>1 Then FlMaster:=True;
 If NTemp>0 Then Tempos[1].T:=0;
 LocL:=0;LocR:=SongEnd;If LocR<=0 Then LocR:=BBTToTick(5,1,0);PosTick:=0;
 LoadMidi:=(NSlot>0);
 Modified:=True;
End;

{ ---- Morceau de demonstration : Ode a la joie (Beethoven, domaine public) }

Procedure DemoNote(P: Integer; Var T: LongInt; Pitch: Integer; Dur: LongInt;
                   Vel: Integer);
Begin
 If Pitch>0 Then EvAdd(P,T,Dur-Dur Div 10,EK_NOTE,Pitch,Vel);
 T:=T+Dur;
End;

Procedure BuildDemo;
Const
 Mel : Array[1..30] Of Byte =
  (64,64,65,67, 67,65,64,62, 60,60,62,64, 64,62,62,
   64,64,65,67, 67,65,64,62, 60,60,62,64, 62,60,60);
 Dur : Array[1..30] Of Byte =
  (4,4,4,4, 4,4,4,4, 4,4,4,4, 6,2,8,
   4,4,4,4, 4,4,4,4, 4,4,4,4, 6,2,8);
 BassN : Array[1..16] Of Byte =
  (36,43,43,43,36,43,43,36,36,43,43,43,36,43,43,36);
Var P1,P2,P3,P4,I,B: Integer; T: LongInt; Q: LongInt;
Begin
 InitSong;
 TempoFix:=1120;
 Q:=PPQ;
 ResetTrack(1);Trk[1].Name:='Melody';Trk[1].Instr:='Piano';Trk[1].Chan:=1;
 ResetTrack(2);Trk[2].Name:='Bass';Trk[2].Instr:='Bass';Trk[2].Chan:=2;
 ResetTrack(3);Trk[3].Name:='Drums';Trk[3].Instr:='Drums';Trk[3].Chan:=10;
 Trk[3].Drum:=True;
 ResetTrack(4);Trk[4].Name:='Strings';Trk[4].Instr:='Strings';Trk[4].Chan:=4;
 P1:=PartNew(1,0,BBTToTick(9,1,0),'Ode');
 P2:=PartNew(2,0,BBTToTick(9,1,0),'Bassline');
 P3:=PartNew(3,0,BBTToTick(9,1,0),'Groove');
 P4:=PartNew(4,BBTToTick(5,1,0),BBTToTick(9,1,0),'Pad');
 T:=0;
 For I:=1 To 30 Do DemoNote(P1,T,Mel[I],Q*Dur[I] Div 4,96);
 T:=0;
 For I:=1 To 16 Do DemoNote(P2,T,BassN[I],Q*2,90);
 T:=0;
 For B:=0 To 7 Do Begin
  EvAdd(P3,B*Q*4,40,EK_NOTE,36,110);
  EvAdd(P3,B*Q*4+Q*2,40,EK_NOTE,36,100);
  EvAdd(P3,B*Q*4+Q,40,EK_NOTE,38,105);
  EvAdd(P3,B*Q*4+Q*3,40,EK_NOTE,38,105);
  For I:=0 To 7 Do EvAdd(P3,B*Q*4+I*(Q Div 2),20,EK_NOTE,42,60+(I And 1)*25);
 End;
 For B:=0 To 3 Do Begin
  T:=B*Q*4;
  If B Mod 2=0 Then Begin
   EvAdd(P4,T,Q*4-20,EK_NOTE,48,70);EvAdd(P4,T,Q*4-20,EK_NOTE,52,70);
   EvAdd(P4,T,Q*4-20,EK_NOTE,55,70);
  End Else Begin
   EvAdd(P4,T,Q*4-20,EK_NOTE,47,70);EvAdd(P4,T,Q*4-20,EK_NOTE,50,70);
   EvAdd(P4,T,Q*4-20,EK_NOTE,55,70);
  End;
 End;
 LocL:=0;LocR:=BBTToTick(9,1,0);PosTick:=0;
 SongName:='ODE.ARR';SongNamed:=False;Modified:=False;
 CurTrk:=1;
End;

{ ---- options ---- }

Procedure SaveOptions;
Var F: Text;
Begin
 {$I-}
 Assign(F,OPTFILE);
 Rewrite(F);
 {$I+}
 If IOResult<>0 Then Begin
  Info('Cannot write CUBASE.OPT.','Ecriture de CUBASE.OPT impossible.',
       'CUBASE.OPT nicht schreibbar.');
  Exit;End;
 WriteLn(F,'LANG ',Lang);
 WriteLn(F,'OUTDEV ',OutDev);
 WriteLn(F,'MPU ',MpuPort);
 WriteLn(F,'VEL ',DefVel);
 WriteLn(F,'COUNTIN ',CountIn);
 WriteLn(F,'AUTOQ ',AutoQ);
 WriteLn(F,'CLICKMODE ',ClickMode);
 WriteLn(F,'HUMVEL ',HumVel);
 WriteLn(F,'HUMLEN ',HumLen);
 WriteLn(F,'FLAGS ',B2B(FlChase),B2B(FlFollow),B2B(FlReset),B2B(FlTempoRec),
   B2B(FlThru),B2B(FlOverdub),B2B(FlClick));
 WriteLn(F,'PRN ',PrnDest);
 Close(F);
 Info('Options saved.','Options sauv'#130'es.','Optionen gespeichert.');
End;

Procedure LoadOptions(UseLang: Boolean);
Var F: Text; L,K,V: String; P,C: Integer; N: LongInt;
 Function Fl(I: Integer): Boolean;
 Begin
  Fl:=(Length(V)>=I) And (V[I]='1');
 End;
Begin
 {$I-}
 Assign(F,OPTFILE);
 Reset(F);
 {$I+}
 If IOResult<>0 Then Exit;
 While Not Eof(F) Do Begin
  ReadLn(F,L);
  P:=Pos(' ',L);
  If P>0 Then Begin
   K:=Upper(Copy(L,1,P-1));V:=Copy(L,P+1,60);
   Val(V,N,C);
   If K='LANG' Then Begin If UseLang And (C=0) Then Lang:=Integer(Clamp(N,0,2));End
   Else If K='OUTDEV' Then Begin If C=0 Then OutDev:=Integer(Clamp(N,0,2));End
   Else If K='MPU' Then Begin If C=0 Then MpuPort:=Integer(N);End
   Else If K='VEL' Then Begin If C=0 Then DefVel:=Integer(Clamp(N,1,127));End
   Else If K='COUNTIN' Then Begin If C=0 Then CountIn:=Integer(Clamp(N,0,4));End
   Else If K='AUTOQ' Then Begin If C=0 Then AutoQ:=Integer(Clamp(N,0,NQUA));End
   Else If K='CLICKMODE' Then Begin If C=0 Then ClickMode:=Integer(Clamp(N,0,2));End
   Else If K='HUMVEL' Then Begin If C=0 Then HumVel:=Integer(Clamp(N,0,40));End
   Else If K='HUMLEN' Then Begin If C=0 Then HumLen:=Integer(Clamp(N,0,50));End
   Else If K='PRN' Then PrnDest:=Copy(V,1,40)
   Else If K='FLAGS' Then Begin
    FlChase:=Fl(1);FlFollow:=Fl(2);FlReset:=Fl(3);FlTempoRec:=Fl(4);
    FlThru:=Fl(5);FlOverdub:=Fl(6);FlClick:=Fl(7);
   End;
  End;
 End;
 Close(F);
End;


{ ====================================================================== }
{                  COMMANDES : TRANSPORT / EDITION / STRUCTURE           }
{ ====================================================================== }

Const
 NOPARTMSG = 'Select a part first.~S'#130'lectionnez d''abord une partie.~'+
             'W'#132'hlen Sie zuerst einen Part.';

Procedure Touch;
Begin
 Modified:=True;
 NeedDraw:=True;
End;

Procedure NoPart;
Begin
 Info(Part3(NOPARTMSG,0),Part3(NOPARTMSG,1),Part3(NOPARTMSG,2));
End;

Procedure SetPos(T: LongInt);
Begin
 If T<0 Then T:=0;
 If Playing Then Begin
  AllNotesOff;
  PlayTick:=T;PosTick:=T;
  PlaySeek(T);
  LastBeat:=FloorDiv(T,BeatTicks)-1;
 End Else PosTick:=T;
 NeedDraw:=True;
End;

Procedure CmdStart;
Begin
 If Playing Then Begin
  If Recording Then Begin StopPlay;End Else StopPlay;
 End Else Begin
  Recording:=False;
  StartPlay(PosTick);
 End;
End;

Procedure CmdStop;
Begin
 StopPlay;
End;

Procedure CmdRecord;
Begin
 If Playing Then Begin
  If Not Recording Then Begin
   Recording:=True;RecTrk:=CurTrk;RecPart:=0;RecT0:=PlayTick;
   NeedDraw:=True;
  End Else StopPlay;
 End Else Begin
  Recording:=True;
  StartPlay(PosTick);
 End;
End;

Procedure CmdRewind;
Begin
 SetPos(Max2(0,CurPos-BarTicks));
 If FlFollow Then ViewBar:=FloorDiv(Max2(0,CurPos),BarTicks);
End;

Procedure CmdForward;
Begin
 SetPos(CurPos+BarTicks);
End;

Procedure CmdGoto;
Var S: String; T: LongInt;
Begin
 S:=PosStr(CurPos);
 While (S<>'') And (S[1]=' ') Do Delete(S,1,1);
 If InputBox(T3('Song position','Position du morceau','Songposition'),
             'bar.beat.tick',S,14) Then
  If ParsePos(S,T) Then SetPos(T);
 NeedDraw:=True;
End;

Procedure CmdSetLoc(Left: Boolean);
Var S: String; T: LongInt;
Begin
 If Left Then S:=PosStr(LocL) Else S:=PosStr(LocR);
 While (S<>'') And (S[1]=' ') Do Delete(S,1,1);
 If InputBox(T3('Locator','Locator','Locator'),'bar.beat.tick',S,14) Then
  If ParsePos(S,T) Then Begin
   If Left Then Begin
    LocL:=T;If LocR<=LocL Then LocR:=LocL+BarTicks;
   End Else Begin
    LocR:=T;If LocL>=LocR Then LocL:=Max2(0,LocR-BarTicks);
   End;
  End;
 NeedDraw:=True;
End;

Procedure LocFromPos(Left: Boolean);
Begin
 If Left Then Begin
  LocL:=CurPos;If LocR<=LocL Then LocR:=LocL+BarTicks;
 End Else Begin
  LocR:=CurPos;If LocL>=LocR Then LocL:=Max2(0,LocR-BarTicks);
 End;
 NeedDraw:=True;
End;

Procedure CmdTempo;
Var S: String; R: Real; C: Integer; V: Integer;
Begin
 S:=TempoStr(TempoAt(CurPos));
 If InputBox('TEMPO','BPM (20-300)',S,8) Then Begin
  Val(S,R,C);
  If C=0 Then Begin
   V:=Round(R*10);
   If V<200 Then V:=200;
   If V>3000 Then V:=3000;
   If FlMaster And (NTemp>0) Then TempoSet(0,V) Else TempoFix:=V;
   Modified:=True;
  End;
 End;
 NeedDraw:=True;
End;

Procedure CmdSignature;
Var S: String; P,C: Integer; N,D: LongInt;
Begin
 S:=IntStr(SigN)+'/'+IntStr(SigD);
 If InputBox(T3('Signature','Signature','Taktart'),'n/d',S,6) Then Begin
  P:=Pos('/',S);
  If P>0 Then Begin
   Val(Copy(S,1,P-1),N,C);
   If C=0 Then Begin
    Val(Copy(S,P+1,5),D,C);
    If (C=0) And (N>=1) And (N<=32) And ((D=1) Or (D=2) Or (D=4) Or (D=8) Or (D=16)
       Or (D=32)) Then Begin
     SigN:=N;SigD:=D;Modified:=True;
    End;
   End;
  End;
 End;
 NeedDraw:=True;
End;

Procedure CmdSync;
Begin
 SyncMode:=(SyncMode+1) Mod 3;
 NeedDraw:=True;
End;

Procedure Toggle(Var B: Boolean);
Begin
 B:=Not B;
 NeedDraw:=True;
End;

Procedure TempoNudge(D: Integer);
Var V: Integer;
Begin
 V:=TempoAt(CurPos)+D;
 If V<200 Then V:=200;
 If V>3000 Then V:=3000;
 If FlMaster And (NTemp>0) Then Begin
  If FlTempoRec And Recording Then TempoSet(Max2(0,PlayTick),V)
  Else TempoSet(0,V);
 End Else TempoFix:=V;
 If FlTempoRec And Recording And (Not FlMaster) Then Begin
  If NTemp=0 Then TempoSet(0,TempoFix);
  TempoSet(Max2(0,PlayTick),V);FlMaster:=True;
 End;
 NeedDraw:=True;
End;

{ ---- fichiers ---- }

Procedure ResetView;
Begin
 ViewBar:=0;CurTrk:=1;ArrTop:=1;View:=V_ARR;EdPart:=0;PlayX:=-1;
End;

Function SaveFirst: Boolean;
Begin
 SaveFirst:=True;
 If Modified Then
  SaveFirst:=ConfirmBox(T3('Discard the changes ?','Abandonner les modifications ?',
                           #129'nderungen verwerfen ?'));
End;

Procedure CmdNew;
Begin
 If Not SaveFirst Then Exit;
 If Playing Then StopPlay;
 InitSong;UndoValid:=False;
 ResetView;
 NeedDraw:=True;
End;

Procedure CmdSaveAs;
Var N: String;
Begin
 N:=SongName;
 If FileSelect(T3('Save arrangement','Sauver l''arrangement','Arrangement speichern'),
               '*.ARR',N) Then Begin
  N:=AddExt(N,'ARR');
  If SaveArr(N) Then Begin
   SongName:=N;SongNamed:=True;Modified:=False;
  End Else Info('Cannot write the file.','Ecriture impossible.',
                'Schreiben nicht m'#148'glich.');
 End;
 NeedDraw:=True;
End;

Procedure CmdSave;
Begin
 If Not SongNamed Then CmdSaveAs
 Else Begin
  If SaveArr(SongName) Then Modified:=False
  Else Info('Cannot write the file.','Ecriture impossible.',
            'Schreiben nicht m'#148'glich.');
  NeedDraw:=True;
 End;
End;

Procedure CmdOpen;
Var N: String;
Begin
 If Not SaveFirst Then Exit;
 N:='';
 If FileSelect(T3('Open arrangement','Ouvrir un arrangement','Arrangement laden'),
               '*.ARR',N) Then Begin
  If Playing Then StopPlay;
  N:=AddExt(N,'ARR');
  If Not LoadArr(N,False) Then
   Info('Cannot read the file.','Lecture impossible.','Lesen nicht m'#148'glich.');
  ResetView;UndoValid:=False;
 End;
 NeedDraw:=True;
End;

Procedure CmdImportMidi;
Var N: String;
Begin
 If Not SaveFirst Then Exit;
 N:='';
 If FileSelect(T3('Import MIDI file','Importer un fichier MIDI','MIDI-Datei importieren'),
               '*.MID',N) Then Begin
  If Playing Then StopPlay;
  If LoadMidi(N) Then Begin
   SongName:=Copy(ShortName(N),1,Pos('.',ShortName(N)+'.')-1)+'.ARR';
   SongNamed:=False;
   ResetView;UndoValid:=False;
  End Else Info('Invalid MIDI file.','Fichier MIDI invalide.','Ung'#129'ltige MIDI-Datei.');
 End;
 NeedDraw:=True;
End;

Procedure CmdExportMidi;
Var N: String;
Begin
 N:=Copy(ShortName(SongName),1,Pos('.',ShortName(SongName)+'.')-1)+'.MID';
 If FileSelect(T3('Export MIDI file','Exporter un fichier MIDI','MIDI-Datei exportieren'),
               '*.MID',N) Then Begin
  N:=AddExt(N,'MID');
  If SaveMidi(N) Then Info('MIDI file written.','Fichier MIDI '#130'crit.',
                           'MIDI-Datei geschrieben.')
  Else Info('Cannot write the file.','Ecriture impossible.',
            'Schreiben nicht m'#148'glich.');
 End;
 NeedDraw:=True;
End;

Procedure CmdDemo;
Begin
 If Not SaveFirst Then Exit;
 If Playing Then StopPlay;
 BuildDemo;
 UndoValid:=False;ResetView;
 NeedDraw:=True;
End;

Procedure CmdQuit;
Begin
 If Modified Then
  If Not ConfirmBox(T3('Quit without saving ?','Quitter sans sauver ?',
                       'Ohne Speichern beenden ?')) Then Exit;
 Quit:=True;
End;

Procedure HardcopyPBM;
Var F: File; Row: Array[1..80] Of Byte; X,Y: Integer; H: String;
Begin
 DrawAll;
 {$I-}
 Assign(F,'CUBASE.PBM');
 Rewrite(F,1);
 {$I+}
 If IOResult<>0 Then Begin
  Info('Cannot write the file.','Ecriture impossible.','Schreiben nicht m'#148'glich.');
  Exit;End;
 HideMouse;
 H:='P4'#10'640 '+IntStr(SCR_H)+#10;
 BlockWrite(F,H[1],Length(H));
 For Y:=0 To SCR_H-1 Do Begin
  FillChar(Row,SizeOf(Row),0);
  For X:=0 To 639 Do
   If GetPixel(X,Y)<>PAPER Then Row[X Shr 3+1]:=Row[X Shr 3+1] Or ($80 Shr (X And 7));
  BlockWrite(F,Row,80);
 End;
 Close(F);
 ShowMouse;
 Info('Screen saved in CUBASE.PBM.','Ecran sauv'#130' dans CUBASE.PBM.',
      'Bildschirm in CUBASE.PBM gesichert.');
End;

{ ---- presse-papiers de parties ---- }

Procedure ClipClear;
Var I: Integer;
Begin
 For I:=1 To ClipN Do
  If ClipP[I].Ev<>Nil Then FreeMem(ClipP[I].Ev,ClipP[I].Cap*SizeOf(TEvt));
 ClipN:=0;
End;

Procedure ClipAdd(Src: Integer);
Begin
 If ClipN>=24 Then Exit;
 Inc(ClipN);
 ClipP[ClipN]:=Parts[Src];
 ClipP[ClipN].Ev:=Nil;ClipP[ClipN].Cap:=0;
 If Parts[Src].Cnt>0 Then Begin
  ClipP[ClipN].Cap:=Parts[Src].Cnt;
  GetMem(ClipP[ClipN].Ev,ClipP[ClipN].Cap*SizeOf(TEvt));
  Move(Parts[Src].Ev^,ClipP[ClipN].Ev^,Parts[Src].Cnt*SizeOf(TEvt));
 End;
End;

Procedure CmdCopyParts(Cut: Boolean);
Var I,N: Integer;
Begin
 N:=SelPartCount;
 If N=0 Then Begin NoPart;Exit;End;
 ClipClear;
 ClipT0:=$7FFFFFF;ClipTrk0:=NTRK;
 For I:=1 To MAXPART Do
  If Parts[I].Used And Parts[I].Sel Then Begin
   ClipAdd(I);
   If Parts[I].Start<ClipT0 Then ClipT0:=Parts[I].Start;
   If Parts[I].Trk<ClipTrk0 Then ClipTrk0:=Parts[I].Trk;
  End;
 If Cut Then Begin
  SaveUndo;
  For I:=1 To MAXPART Do If Parts[I].Used And Parts[I].Sel Then PartFree(I);
  Touch;
 End;
End;

Procedure CmdPaste;
Var I,K,P,Tk: Integer; D: LongInt;
Begin
 If ClipN=0 Then Begin
  Info('The clipboard is empty.','Le presse-papiers est vide.','Die Zwischenablage ist leer.');
  Exit;
 End;
 SaveUndo;
 For I:=1 To MAXPART Do Parts[I].Sel:=False;
 D:=PosTick-ClipT0;
 For I:=1 To ClipN Do Begin
  Tk:=CurTrk+(ClipP[I].Trk-ClipTrk0);
  If Tk>NTRK Then Tk:=NTRK;
  P:=PartNew(Tk,ClipP[I].Start+D,ClipP[I].Stop+D,ClipP[I].Name);
  If P>0 Then Begin
   Parts[P].PP:=ClipP[I].PP;Parts[P].Mute:=ClipP[I].Mute;Parts[P].Sel:=True;
   For K:=1 To ClipP[I].Cnt Do
    EvAdd(P,ClipP[I].Ev^[K].T,ClipP[I].Ev^[K].Len,ClipP[I].Ev^[K].Kind,
          ClipP[I].Ev^[K].D1,ClipP[I].Ev^[K].D2);
  End;
 End;
 Touch;
End;

Procedure CmdDeleteParts;
Var I: Integer;
Begin
 If SelPartCount=0 Then Begin NoPart;Exit;End;
 SaveUndo;
 For I:=1 To MAXPART Do If Parts[I].Used And Parts[I].Sel Then PartFree(I);
 Touch;
End;

Var
 EvClipN  : Integer;
 EvClip   : Array[1..200] Of TEvt;
 EvClipT0 : LongInt;

Procedure DeleteSelEvents;
Var I: Integer;
Begin
 If (EdPart<1) Or (Not Parts[EdPart].Used) Then Exit;
 SaveUndo;
 For I:=Parts[EdPart].Cnt DownTo 1 Do
  If Parts[EdPart].Ev^[I].Sel Then EvDel(EdPart,I);
 ListSel:=0;
 Touch;
End;

Procedure CmdCopyEv(Cut: Boolean);
Var I,N: Integer;
Begin
 If (EdPart<1) Or (Not Parts[EdPart].Used) Then Exit;
 N:=0;EvClipT0:=$7FFFFFF;
 For I:=1 To Parts[EdPart].Cnt Do
  If Parts[EdPart].Ev^[I].Sel And (N<200) Then Begin
   Inc(N);EvClip[N]:=Parts[EdPart].Ev^[I];
   If Parts[EdPart].Ev^[I].T<EvClipT0 Then EvClipT0:=Parts[EdPart].Ev^[I].T;
  End;
 If N=0 Then Begin
  Info('Select some events first.','S'#130'lectionnez d''abord des '#130'v'#130'nements.',
       'W'#132'hlen Sie zuerst Events.');
  Exit;
 End;
 EvClipN:=N;
 If Cut Then DeleteSelEvents;
End;

Procedure CmdPasteEv;
Var I,K: Integer; D: LongInt;
Begin
 If (EdPart<1) Or (Not Parts[EdPart].Used) Then Exit;
 If EvClipN=0 Then Begin
  Info('The clipboard is empty.','Le presse-papiers est vide.','Die Zwischenablage ist leer.');
  Exit;
 End;
 SaveUndo;
 For I:=1 To Parts[EdPart].Cnt Do Parts[EdPart].Ev^[I].Sel:=False;
 D:=Max2(0,PosTick-Parts[EdPart].Start)-EvClipT0;
 For I:=1 To EvClipN Do Begin
  If Parts[EdPart].Start+EvClip[I].T+D>=Parts[EdPart].Stop Then
   Parts[EdPart].Stop:=(FloorDiv(Parts[EdPart].Start+EvClip[I].T+D,BarTicks)+1)*BarTicks;
  K:=EvAdd(EdPart,EvClip[I].T+D,EvClip[I].Len,EvClip[I].Kind,EvClip[I].D1,EvClip[I].D2);
  If K>0 Then Parts[EdPart].Ev^[K].Sel:=True;
 End;
 Touch;
End;

Procedure CmdSelAll(V: Boolean);
Var I: Integer;
Begin
 If View=V_ARR Then Begin
  For I:=1 To MAXPART Do If Parts[I].Used Then Parts[I].Sel:=V;
 End Else If (EdPart>=1) And Parts[EdPart].Used Then
  For I:=1 To Parts[EdPart].Cnt Do Parts[EdPart].Ev^[I].Sel:=V;
 NeedDraw:=True;
End;

{ ---- structure ---- }

Procedure CmdCreatePart;
Var P: Integer; L,R: LongInt;
Begin
 L:=LocL;R:=LocR;
 If R<=L Then R:=L+BarTicks;
 SaveUndo;
 P:=PartNew(CurTrk,L,R,Trk[CurTrk].Name);
 If P=0 Then Begin
  Info('No more parts available.','Plus de parties disponibles.','Keine Parts mehr frei.');
  Exit;
 End;
 Parts[P].Sel:=True;
 Touch;
End;

Procedure SplitPart(P: Integer; T: LongInt);
Var Q,I: Integer; Rel: LongInt;
Begin
 If (T<=Parts[P].Start) Or (T>=Parts[P].Stop) Then Exit;
 Q:=PartNew(Parts[P].Trk,T,Parts[P].Stop,Parts[P].Name);
 If Q=0 Then Exit;
 Parts[Q].PP:=Parts[P].PP;Parts[Q].Mute:=Parts[P].Mute;
 Rel:=T-Parts[P].Start;
 For I:=1 To Parts[P].Cnt Do
  If Parts[P].Ev^[I].T>=Rel Then
   EvAdd(Q,Parts[P].Ev^[I].T-Rel,Parts[P].Ev^[I].Len,Parts[P].Ev^[I].Kind,
         Parts[P].Ev^[I].D1,Parts[P].Ev^[I].D2);
 For I:=Parts[P].Cnt DownTo 1 Do
  If Parts[P].Ev^[I].T>=Rel Then EvDel(P,I);
 Parts[P].Stop:=T;
End;

Procedure CmdSplit;
Var I,N: Integer;
Begin
 N:=0;
 SaveUndo;
 For I:=1 To MAXPART Do
  If Parts[I].Used And Parts[I].Sel And (PosTick>Parts[I].Start) And
     (PosTick<Parts[I].Stop) Then Begin SplitPart(I,PosTick);Inc(N);End;
 If N=0 Then Info('Move the song position inside the selected part.',
   'Placez la position du morceau '#133' l''int'#130'rieur de la partie s'#130'lectionn'#130'e.',
   'Songposition in den gew'#132'hlten Part setzen.')
 Else Touch;
End;

{ colle la partie Q a la suite de P }
Procedure GlueParts(P,Q: Integer);
Var I: Integer; Off: LongInt;
Begin
 Off:=Parts[Q].Start-Parts[P].Start;
 For I:=1 To Parts[Q].Cnt Do
  EvAdd(P,Parts[Q].Ev^[I].T+Off,Parts[Q].Ev^[I].Len,Parts[Q].Ev^[I].Kind,
        Parts[Q].Ev^[I].D1,Parts[Q].Ev^[I].D2);
 If Parts[Q].Stop>Parts[P].Stop Then Parts[P].Stop:=Parts[Q].Stop;
 PartFree(Q);
End;

{ prochaine partie de la meme piste apres P }
Function NextPartOnTrack(P: Integer): Integer;
Var I,B: Integer;
Begin
 B:=0;
 For I:=1 To MAXPART Do
  If Parts[I].Used And (I<>P) And (Parts[I].Trk=Parts[P].Trk) And
     (Parts[I].Start>=Parts[P].Start) Then
   If (B=0) Or (Parts[I].Start<Parts[B].Start) Then B:=I;
 NextPartOnTrack:=B;
End;

Procedure CmdGlue;
Var I,Q,N: Integer;
Begin
 If SelPartCount=0 Then Begin NoPart;Exit;End;
 SaveUndo;
 N:=0;
 For I:=1 To MAXPART Do
  If Parts[I].Used And Parts[I].Sel Then Begin
   Q:=NextPartOnTrack(I);
   While (Q>0) And Parts[Q].Sel Do Begin
    GlueParts(I,Q);Inc(N);
    Q:=NextPartOnTrack(I);
   End;
  End;
 If N=0 Then
  Info('Select at least two parts on the same track.',
       'S'#130'lectionnez au moins deux parties de la m'#136'me piste.',
       'Mindestens zwei Parts derselben Spur w'#132'hlen.');
 Touch;
End;

Procedure CmdRepeat;
Var V: LongInt; I,K,N,Q,Cnt0: Integer; L: LongInt;
Begin
 If SelPartCount=0 Then Begin NoPart;Exit;End;
 V:=1;
 If Not AskNum(T3('Repeat','R'#130'p'#130'ter','Wiederholen'),
               T3('Number of copies','Nombre de copies','Anzahl Kopien'),V,1,64) Then Exit;
 SaveUndo;
 Cnt0:=MAXPART;
 For I:=1 To Cnt0 Do
  If Parts[I].Used And Parts[I].Sel Then Begin
   L:=Parts[I].Stop-Parts[I].Start;
   For N:=1 To V Do Begin
    Q:=PartNew(Parts[I].Trk,Parts[I].Start+L*N,Parts[I].Stop+L*N,Parts[I].Name);
    If Q>0 Then Begin
     Parts[Q].PP:=Parts[I].PP;Parts[Q].Mute:=Parts[I].Mute;
     For K:=1 To Parts[I].Cnt Do
      EvAdd(Q,Parts[I].Ev^[K].T,Parts[I].Ev^[K].Len,Parts[I].Ev^[K].Kind,
            Parts[I].Ev^[K].D1,Parts[I].Ev^[K].D2);
    End;
   End;
  End;
 Touch;
End;

Procedure CmdFitLocators;
Var P: Integer;
Begin
 P:=FirstSelPart;
 If P=0 Then Begin NoPart;Exit;End;
 SaveUndo;
 Parts[P].Start:=LocL;Parts[P].Stop:=LocR;
 Touch;
End;

Procedure CmdMovePos;
Var P: Integer; D: LongInt;
Begin
 P:=FirstSelPart;
 If P=0 Then Begin NoPart;Exit;End;
 SaveUndo;
 D:=PosTick-Parts[P].Start;
 For P:=1 To MAXPART Do
  If Parts[P].Used And Parts[P].Sel Then Begin
   Parts[P].Start:=Parts[P].Start+D;Parts[P].Stop:=Parts[P].Stop+D;
  End;
 Touch;
End;

Procedure CmdMuteParts;
Var P: Integer;
Begin
 If SelPartCount=0 Then Begin NoPart;Exit;End;
 For P:=1 To MAXPART Do
  If Parts[P].Used And Parts[P].Sel Then Parts[P].Mute:=Not Parts[P].Mute;
 Touch;
End;

Procedure CmdInsertBars(Ins: Boolean);
Var V: LongInt; I,K: Integer; At,N,E1: LongInt; Cap: String;
Begin
 V:=1;
 If Ins Then Cap:=T3('Insert bars','Ins'#130'rer des mesures','Takte einf'#129'gen')
 Else Cap:=T3('Delete bars','Supprimer des mesures','Takte l'#148'schen');
 If Not AskNum(Cap,T3('Number of bars (at the position)','Nombre de mesures (a la position)',
   'Anzahl Takte (an der Position)'),V,1,200) Then Exit;
 SaveUndo;
 At:=FloorDiv(PosTick,BarTicks)*BarTicks;
 N:=V*BarTicks;
 For I:=1 To MAXPART Do
  If Parts[I].Used Then Begin
   If Ins Then Begin
    If Parts[I].Start>=At Then Begin
     Parts[I].Start:=Parts[I].Start+N;Parts[I].Stop:=Parts[I].Stop+N;
    End Else If Parts[I].Stop>At Then Begin
     For K:=1 To Parts[I].Cnt Do
      If Parts[I].Start+Parts[I].Ev^[K].T>=At Then
       Parts[I].Ev^[K].T:=Parts[I].Ev^[K].T+N;
     Parts[I].Stop:=Parts[I].Stop+N;
    End;
   End Else Begin
    E1:=At+N;
    If Parts[I].Start>=E1 Then Begin
     Parts[I].Start:=Parts[I].Start-N;Parts[I].Stop:=Parts[I].Stop-N;
    End Else If (Parts[I].Start>=At) And (Parts[I].Stop<=E1) Then PartFree(I)
    Else If Parts[I].Stop>At Then Begin
     For K:=Parts[I].Cnt DownTo 1 Do Begin
      If (Parts[I].Start+Parts[I].Ev^[K].T>=At) And
         (Parts[I].Start+Parts[I].Ev^[K].T<E1) Then EvDel(I,K)
      Else If Parts[I].Start+Parts[I].Ev^[K].T>=E1 Then
       Parts[I].Ev^[K].T:=Parts[I].Ev^[K].T-N;
     End;
     If Parts[I].Stop>E1 Then Parts[I].Stop:=Parts[I].Stop-N
     Else Parts[I].Stop:=At;
     If Parts[I].Stop<=Parts[I].Start Then PartFree(I);
    End;
   End;
  End;
 For K:=1 To NTemp Do
  If K>1 Then Begin
   If Ins And (Tempos[K].T>=At) Then Tempos[K].T:=Tempos[K].T+N
   Else If (Not Ins) And (Tempos[K].T>=At+N) Then Tempos[K].T:=Tempos[K].T-N;
  End;
 Touch;
End;

Procedure CmdRenamePart;
Var P: Integer; S: String;
Begin
 P:=FirstSelPart;
 If View<>V_ARR Then P:=EdPart;
 If P<1 Then Begin NoPart;Exit;End;
 S:=Parts[P].Name;
 If InputBox(T3('Part name','Nom de la partie','Part-Name'),'Name',S,12) Then Begin
  SaveUndo;
  Parts[P].Name:=Copy(S,1,12);Touch;
 End;
 NeedDraw:=True;
End;

Procedure CmdRenameTrack;
Var S: String;
Begin
 S:=Trk[CurTrk].Name;
 If InputBox(T3('Track name','Nom de la piste','Spurname'),'Name',S,12) Then Begin
  Trk[CurTrk].Name:=Copy(S,1,12);Touch;
 End;
 NeedDraw:=True;
End;

{ ---- fonctions sur les evenements ---- }

Procedure TargetRange(Var P1,P2: Integer);
Begin
 If View<>V_ARR Then Begin P1:=EdPart;P2:=EdPart;End
 Else Begin P1:=1;P2:=MAXPART;End;
End;

Function Chosen(P,I: Integer): Boolean;
Var K: Integer; AnySel: Boolean;
Begin
 If View=V_ARR Then Chosen:=Parts[P].Sel
 Else Begin
  AnySel:=False;
  For K:=1 To Parts[P].Cnt Do If Parts[P].Ev^[K].Sel Then AnySel:=True;
  Chosen:=(Not AnySel) Or Parts[P].Ev^[I].Sel;
 End;
End;

{ Op : 1 transposition, 2 velocite +, 3 longueur fixe, 4 legato, 5 doublons,
  6 controleurs, 7 allegement, 8 quantification, 9 sur-quantification,
  10 velocite % }
Procedure ApplyEv(Op: Integer; A: LongInt);
Var P,I,K,P1,P2,Last: Integer; T,E1: LongInt;
Begin
 TargetRange(P1,P2);
 If (View=V_ARR) And (SelPartCount=0) Then Begin NoPart;Exit;End;
 If (P1<1) Or (Not Parts[P1].Used) Then Begin NoPart;Exit;End;
 SaveUndo;
 For P:=P1 To P2 Do
  If Parts[P].Used And (Parts[P].Ev<>Nil) And ((View<>V_ARR) Or Parts[P].Sel) Then Begin
   Case Op Of
    1: For I:=1 To Parts[P].Cnt Do
        If (Parts[P].Ev^[I].Kind=EK_NOTE) And Chosen(P,I) Then
         Parts[P].Ev^[I].D1:=Integer(Clamp(Parts[P].Ev^[I].D1+A,0,127));
    2: For I:=1 To Parts[P].Cnt Do
        If (Parts[P].Ev^[I].Kind=EK_NOTE) And Chosen(P,I) Then
         Parts[P].Ev^[I].D2:=Integer(Clamp(Parts[P].Ev^[I].D2+A,1,127));
    10: For I:=1 To Parts[P].Cnt Do
        If (Parts[P].Ev^[I].Kind=EK_NOTE) And Chosen(P,I) Then
         Parts[P].Ev^[I].D2:=Integer(Clamp(Parts[P].Ev^[I].D2*A Div 100,1,127));
    3: For I:=1 To Parts[P].Cnt Do
        If (Parts[P].Ev^[I].Kind=EK_NOTE) And Chosen(P,I) Then
         Parts[P].Ev^[I].Len:=A;
    4: For I:=1 To Parts[P].Cnt Do
        If (Parts[P].Ev^[I].Kind=EK_NOTE) And Chosen(P,I) Then Begin
         E1:=$7FFFFFF;
         For K:=1 To Parts[P].Cnt Do
          If (Parts[P].Ev^[K].Kind=EK_NOTE) And (Parts[P].Ev^[K].T>Parts[P].Ev^[I].T)
             And (Parts[P].Ev^[K].T<E1) Then E1:=Parts[P].Ev^[K].T;
         If E1<>$7FFFFFF Then Parts[P].Ev^[I].Len:=E1-Parts[P].Ev^[I].T;
        End;
    5: For I:=Parts[P].Cnt DownTo 2 Do
        If (Parts[P].Ev^[I].Kind=EK_NOTE) And Chosen(P,I) Then Begin
         K:=1;
         While K<I Do Begin
          If (Parts[P].Ev^[K].Kind=EK_NOTE) And
             (Parts[P].Ev^[K].T=Parts[P].Ev^[I].T) And
             (Parts[P].Ev^[K].D1=Parts[P].Ev^[I].D1) Then Begin
           EvDel(P,I);K:=I;
          End;
          Inc(K);
         End;
        End;
    6: For I:=Parts[P].Cnt DownTo 1 Do
        If (Parts[P].Ev^[I].Kind<>EK_NOTE) And Chosen(P,I) Then EvDel(P,I);
    7: Begin
        Last:=-1;T:=-1;
        For I:=Parts[P].Cnt DownTo 1 Do
         If (Parts[P].Ev^[I].Kind=EK_CTRL) And Chosen(P,I) Then Begin
          If (Last>=0) And (Parts[P].Ev^[I].D1=Last) And
             (T-Parts[P].Ev^[I].T<A) Then EvDel(P,I)
          Else Begin Last:=Parts[P].Ev^[I].D1;T:=Parts[P].Ev^[I].T;End;
         End;
       End;
    8: Begin
        For I:=1 To Parts[P].Cnt Do
         If Chosen(P,I) Then Parts[P].Ev^[I].T:=Quant(Parts[P].Ev^[I].T,A);
        PartSort(P);
       End;
    9: Begin
        For I:=1 To Parts[P].Cnt Do
         If Chosen(P,I) Then Begin
          Parts[P].Ev^[I].T:=Quant(Parts[P].Ev^[I].T,A);
          If Parts[P].Ev^[I].Kind=EK_NOTE Then Begin
           Parts[P].Ev^[I].Len:=Quant(Parts[P].Ev^[I].Len,A);
           If Parts[P].Ev^[I].Len<A Then Parts[P].Ev^[I].Len:=A;
          End;
         End;
        PartSort(P);
       End;
   End;
  End;
 Touch;
End;

Procedure CmdQuantize;
Begin
 If QuaTk[QuaI]<=1 Then Begin
  Info('Set a QUANTIZE value first.','Choisissez d''abord une valeur QUANTIZE.',
       'Zuerst einen QUANTIZE-Wert w'#132'hlen.');
  Exit;
 End;
 ApplyEv(8,QuaTk[QuaI]);
End;

Procedure CmdOverQuantize;
Begin
 If QuaTk[QuaI]<=1 Then Begin
  Info('Set a QUANTIZE value first.','Choisissez d''abord une valeur QUANTIZE.',
       'Zuerst einen QUANTIZE-Wert w'#132'hlen.');
  Exit;
 End;
 ApplyEv(9,QuaTk[QuaI]);
End;

Procedure CmdTranspose;
Var V: LongInt;
Begin
 V:=0;
 If AskNum(T3('Transpose','Transposer','Transponieren'),
           T3('Semitones','Demi-tons','Halbt'#148'ne'),V,-96,96) Then ApplyEv(1,V);
End;

Procedure CmdVelocity;
Var V: LongInt;
Begin
 V:=10;
 If AskNum(T3('Velocity','V'#130'locit'#130,'Velocity'),T3('Add (+/-)','Ajouter (+/-)','Addieren (+/-)'),
           V,-126,126) Then ApplyEv(2,V);
End;

Procedure CmdVelPct;
Var V: LongInt;
Begin
 V:=120;
 If AskNum(T3('Velocity','V'#130'locit'#130,'Velocity'),'%',V,1,400) Then ApplyEv(10,V);
End;

Procedure CmdFixLen;
Var V: LongInt;
Begin
 V:=PPQ Div 2;
 If AskNum(T3('Fixed length','Longueur fixe','Feste L'#132'nge'),
           T3('Ticks (192 = quarter)','Ticks (192 = noire)','Ticks (192 = Viertel)'),
           V,1,3072) Then ApplyEv(3,V);
End;

Procedure CmdThin;
Var V: LongInt;
Begin
 V:=24;
 If AskNum(T3('Thin out','All'#130'ger','Ausd'#129'nnen'),'Ticks',V,1,768) Then ApplyEv(7,V);
End;

Procedure CmdLogical;
Var Fm,To1,Act,Val1: LongInt; I,P,P1,P2: Integer;
Begin
 OLbl[1]:=T3('Pitch from','Hauteur de','Tonh'#148'he von');OOpt[1]:='#0..127';OVal[1]:=0;
 OLbl[2]:=T3('Pitch to','Hauteur '#133,'Tonh'#148'he bis');OOpt[2]:='#0..127';OVal[2]:=127;
 OLbl[3]:=T3('Action','Action','Aktion');
 OOpt[3]:='Transpose|Velocity +|Velocity set|Length set|Delete';OVal[3]:=0;
 OLbl[4]:=T3('Value','Valeur','Wert');OOpt[4]:='#-96..400';OVal[4]:=12;
 If Not OptBox('LOGICAL EDIT',4) Then Exit;
 Fm:=OVal[1];To1:=OVal[2];Act:=OVal[3];Val1:=OVal[4];
 TargetRange(P1,P2);
 If (View=V_ARR) And (SelPartCount=0) Then Begin NoPart;Exit;End;
 If (P1<1) Or (Not Parts[P1].Used) Then Begin NoPart;Exit;End;
 SaveUndo;
 For P:=P1 To P2 Do
  If Parts[P].Used And (Parts[P].Ev<>Nil) And ((View<>V_ARR) Or Parts[P].Sel) Then
   For I:=Parts[P].Cnt DownTo 1 Do
    If (Parts[P].Ev^[I].Kind=EK_NOTE) And (Parts[P].Ev^[I].D1>=Fm) And
       (Parts[P].Ev^[I].D1<=To1) And Chosen(P,I) Then Begin
     Case Act Of
      0: Parts[P].Ev^[I].D1:=Integer(Clamp(Parts[P].Ev^[I].D1+Val1,0,127));
      1: Parts[P].Ev^[I].D2:=Integer(Clamp(Parts[P].Ev^[I].D2+Val1,1,127));
      2: Parts[P].Ev^[I].D2:=Integer(Clamp(Val1,1,127));
      3: Parts[P].Ev^[I].Len:=Max2(1,Val1);
      4: EvDel(P,I);
     End;
    End;
 Touch;
End;


{ ====================================================================== }
{                       BOITES DE DIALOGUE                               }
{ ====================================================================== }

Procedure CmdAbout;
Var X1,Y1,X2,Y2: Integer; E: TEvent; Done: Boolean;
Begin
 X1:=100;Y1:=70;X2:=540;Y2:=330;
 HideMouse;
 DlgBox(X1,Y1,X2,Y2,'CUBASE',True);
 SetTextStyle(DefaultFont,HorizDir,4);
 SetColor(INK);
 OutTextXY(X1+26,Y1+50,'Cubase');
 OutTextXY(X1+27,Y1+50,'Cubase');
 SetTextStyle(DefaultFont,HorizDir,1);
 SetLineStyle(SolidLn,0,3);
 Line(X1+26,Y1+88,X1+176,Y1+82);
 SetLineStyle(SolidLn,0,1);
 BText(X1+250,Y1+34,T3('PROGRAM BY:','PROGRAMME DE :','PROGRAMM VON :'));
 PText(X1+250,Y1+50,'Sylvain Maltais');
 PText(X1+250,Y1+62,'Gladir / OFFICE-0');
 PText(X1+250,Y1+78,'MIDI sequencer clone');
 BText(X1+26,Y1+104,T3('VERSION ','VERSION ','VERSION ')+VERSION_TEXT);
 PText(X1+26,Y1+132,T3('FREE EVENTS  - ','EVENEMENTS LIBRES - ','FREIE EVENTS - ')+
   IntStr(POOL_EV-EvUsed));
 PText(X1+26,Y1+146,T3('FREE PARTS   - ','PARTIES LIBRES    - ','FREIE PARTS  - ')+
   IntStr(MAXPART-PartCount));
 PText(X1+26,Y1+160,T3('FREE MEMORY  - ','MEMOIRE LIBRE     - ','FREIER SPEICHER - ')+
   IntStr(MemFree Div 1024)+' KB');
 PText(X1+250,Y1+132,'TOTAL EVENTS '+IntStr(POOL_EV));
 PText(X1+250,Y1+146,'TOTAL PARTS  '+IntStr(MAXPART));
 PText(X1+250,Y1+160,'TOTAL TRACKS '+IntStr(NTRK));
 PText(X1+26,Y1+196,T3('Language: EN / FR / DE (LANGUAGE=EN|GR)',
   'Langue : FR / EN / DE (LANGUAGE=EN|GR)','Sprache: DE / EN / FR (LANGUAGE=EN|GR)'));
 PText(X1+26,Y1+222,'https://www.gladir.com/office-0');
 Button((X1+X2) Div 2-30,Y2-28,(X1+X2) Div 2+30,Y2-10,'OK',True,True);
 ShowMouse;
 Done:=False;
 Repeat
  PollEvent(E);
  If E.Kind=1 Then Begin
   If (E.Key=K_ENTER) Or (E.Key=K_ESC) Or (E.Key=32) Then Done:=True;
  End Else If E.Kind=2 Then Done:=True;
 Until Done;
 NeedDraw:=True;
End;

Procedure CmdFreeMem;
Begin
 MsgBox(T3('Free memory','M'#130'moire libre','Freier Speicher'),
  T3('Free memory: ','M'#130'moire libre : ','Freier Speicher: ')+IntStr(MemFree Div 1024)+' KB|'+
  T3('Free events: ','Evenements libres : ','Freie Events: ')+IntStr(POOL_EV-EvUsed));
End;

Procedure CmdHelp;
Begin
 MsgBox(T3('Help','Aide','Hilfe'),
  T3('F1 Arrange  F2 Key  F3 Score  F4 Grid  F5 Drum  F6 Master|',
     'F1 Arrangement  F2 Key  F3 Partition  F4 Grille  F5 Batterie  F6 Ma'#136'tre|',
     'F1 Arrange  F2 Key  F3 Partitur  F4 Grid  F5 Drum  F6 Master|')+
  T3('SPACE = play / stop    * = record    Home = start|',
     'ESPACE = jouer / arr'#136'ter    * = enregistrer    Origine = d'#130'but|',
     'LEERTASTE = Play / Stop    * = Aufnahme    Pos1 = Anfang|')+
  T3('F7 Play parameter   F8 MIDI processor   F9/F10 tempo -/+|',
     'F7 Param'#138'tres de lecture   F8 Processeur MIDI   F9/F10 tempo -/+|',
     'F7 Wiedergabe-Parameter   F8 MIDI-Prozessor   F9/F10 Tempo -/+|')+
  T3('Z..M and Q..P = piano keys, - + = octave|',
     'Z..M et Q..P = touches de piano, - + = octave|',
     'Z..M und Q..P = Klaviertasten, - + = Oktave|')+
  T3('[ ] set left/right locator    Del delete    Esc stop / keep|',
     '[ ] locator gauche/droit    Suppr effacer    Echap arr'#136'ter / garder|',
     '[ ] linker/rechter Locator    Entf l'#148'schen    Esc Stop / Behalten|')+
  T3('Mouse: right button = copy drag, double click = edit part|',
     'Souris : bouton droit = copie par glisser, double clic = '#130'diter|',
     'Maus: rechte Taste = Kopieren, Doppelklick = Part bearbeiten|')+
  T3('Tools: ARROW PENCIL ERASER SCISSORS GLUE MUTE (click MOUSE)',
     'Outils : FLECHE CRAYON GOMME CISEAUX COLLE MUET (clic MOUSE)',
     'Werkzeuge: PFEIL STIFT RADIERER SCHERE KLEBER MUTE (MOUSE)'));
End;

{ ---- boite de parametres de lecture ---- }

Type
 TItem = Record
  X1,Y1,X2,Y2,Id : Integer;
 End;

Var
 Itm : Array[1..60] Of TItem;
 NItm : Integer;

Procedure ItmAdd(Id,A,B,C,D: Integer);
Begin
 If NItm<60 Then Begin
  Inc(NItm);
  Itm[NItm].X1:=A;Itm[NItm].Y1:=B;Itm[NItm].X2:=C;Itm[NItm].Y2:=D;Itm[NItm].Id:=Id;
 End;
End;

Function ItmAt(X,Y: LongInt): Integer;
Var I: Integer;
Begin
 ItmAt:=0;
 For I:=1 To NItm Do
  If InBox(X,Y,Itm[I].X1,Itm[I].Y1,Itm[I].X2,Itm[I].Y2) Then ItmAt:=Itm[I].Id;
End;

Function PrgStr(V: Integer): String;
Begin
 If V<0 Then PrgStr:='OFF' Else PrgStr:=IntStr(V);
End;

Procedure CmdDrumMap;
Var I,K: Integer; S: String;
Begin
 Repeat
  LstN:=NDRUM;
  For I:=1 To NDRUM Do
   LstItem[I]:=Copy(DrumNm[I]+'          ',1,10)+PadL(IntStr(DrumNote[I]),4)+'  '+
               NoteName(DrumNote[I]);
  K:=ChooseBox('DRUM MAP',1);
  If K>0 Then Begin
   S:=DrumNm[K];
   If InputBox('DRUM MAP',T3('Name','Nom','Name'),S,8) Then DrumNm[K]:=Copy(S,1,8);
   S:=IntStr(DrumNote[K]);
   If InputBox('DRUM MAP',T3('Note (0-127 or C3)','Note (0-127 ou C3)','Note (0-127 oder C3)'),S,5) Then
    If ParseNote(S,I) Then DrumNote[K]:=I;
   Modified:=True;
  End;
 Until K=0;
 NeedDraw:=True;
End;

Procedure DlgPlayParam;
Const
 PLbl : Array[0..6] Of String[12] =
  ('TRANSPOSE','VELOCITY','DELAY','LENGTH','COMPRESSION','PRG CHANGE','VOLUME');
Var X1,Y1,X2,Y2,Y0,I,Id,Tab,PI,Tk: Integer; E: TEvent; Done,Redraw,Right: Boolean;
 PP: ^TPlayPar; S: String; V: LongInt; T: LongInt; Ok: Boolean;

 Function PartOk: Boolean;
 Begin
  PartOk:=(PI>=1) And (PI<=MAXPART);
  If PartOk Then PartOk:=Parts[PI].Used;
 End;

 Procedure Draw;
 Var K,Y: Integer;
 Begin
  HideMouse;
  NItm:=0;
  DlgBox(X1,Y1,X2,Y2,'PLAY PARAMETER',False);
  Y0:=Y1+TB_H+46;
  ValBox(X1+12,Y1+TB_H+8,X1+92,Y1+TB_H+28,'PART',Tab=1);ItmAdd(1,X1+12,Y1+TB_H+8,X1+92,Y1+TB_H+28);
  ValBox(X1+96,Y1+TB_H+8,X1+176,Y1+TB_H+28,'TRACK',Tab=2);ItmAdd(2,X1+96,Y1+TB_H+8,X1+176,Y1+TB_H+28);
  ValBox(X1+180,Y1+TB_H+8,X1+330,Y1+TB_H+28,'ARRANGEMENT',Tab=3);ItmAdd(3,X1+180,Y1+TB_H+8,X1+330,Y1+TB_H+28);
  { colonne gauche }
  Case Tab Of
   1: If PartOk Then Begin
       PText(X1+14,Y0+4,'PART');ValBox(X1+80,Y0,X1+250,Y0+16,Parts[PI].Name,False);ItmAdd(10,X1+80,Y0,X1+250,Y0+16);
       PText(X1+14,Y0+28,'TRACK');ValBox(X1+80,Y0+24,X1+250,Y0+40,Trk[Parts[PI].Trk].Name,False);
       PText(X1+14,Y0+52,'START');ValBox(X1+80,Y0+48,X1+250,Y0+64,PosStr(Parts[PI].Start),False);ItmAdd(16,X1+80,Y0+48,X1+250,Y0+64);
       PText(X1+14,Y0+76,'END');ValBox(X1+80,Y0+72,X1+250,Y0+88,PosStr(Parts[PI].Stop),False);ItmAdd(17,X1+80,Y0+72,X1+250,Y0+88);
       PText(X1+14,Y0+100,'MUTE');
       If Parts[PI].Mute Then S:='ON' Else S:='OFF';
       ValBox(X1+80,Y0+96,X1+140,Y0+112,S,Parts[PI].Mute);ItmAdd(18,X1+80,Y0+96,X1+140,Y0+112);
      End Else Begin
       PText(X1+14,Y0+4,T3('No part selected','Aucune partie s'#130'lectionn'#130'e','Kein Part gew'#132'hlt'));
      End;
   2: Begin
       PText(X1+14,Y0+4,'TRACK');ValBox(X1+80,Y0,X1+250,Y0+16,Trk[Tk].Name,False);ItmAdd(10,X1+80,Y0,X1+250,Y0+16);
       PText(X1+14,Y0+28,'INSTR');ValBox(X1+80,Y0+24,X1+250,Y0+40,Trk[Tk].Instr,False);ItmAdd(11,X1+80,Y0+24,X1+250,Y0+40);
       PText(X1+14,Y0+52,'CHANNEL');ValBox(X1+96,Y0+48,X1+136,Y0+64,IntStr(Trk[Tk].Chan),False);ItmAdd(12,X1+96,Y0+48,X1+136,Y0+64);
       PText(X1+150,Y0+52,'OUTPUT');ValBox(X1+206,Y0+48,X1+270,Y0+64,OutLbl[Trk[Tk].Outp],False);ItmAdd(13,X1+206,Y0+48,X1+270,Y0+64);
       Button(X1+14,Y0+72,X1+110,Y0+90,'DRUM MAP',False,True);ItmAdd(14,X1+14,Y0+72,X1+110,Y0+90);
       If Trk[Tk].Drum Then S:='DRUM ON' Else S:='DRUM OFF';
       ValBox(X1+120,Y0+72,X1+210,Y0+90,S,Trk[Tk].Drum);ItmAdd(15,X1+120,Y0+72,X1+210,Y0+90);
       PText(X1+14,Y0+100,'FILTER');
       For K:=0 To 5 Do Begin
        Y:=Y0+114+K*17;
        If (Trk[Tk].Filt And (1 Shl K))<>0 Then Box(X1+14,Y,X1+26,Y+12,INK)
        Else Begin Box(X1+14,Y,X1+26,Y+12,PAPER);Frame(X1+14,Y,X1+26,Y+12);End;
        PText(X1+34,Y+3,FiltName[K]);
        ItmAdd(30+K,X1+14,Y,X1+190,Y+14);
       End;
      End;
   3: Begin
       PText(X1+14,Y0+4,'ARRANGEMENT');ValBox(X1+14,Y0+24,X1+250,Y0+40,ShortName(SongName),False);
       PText(X1+14,Y0+60,T3('Global parameters added to','Parametres globaux ajoutes aux','Globale Parameter zu'));
       PText(X1+14,Y0+72,T3('every part and track.','parties et pistes.','Parts und Spuren addiert.'));
      End;
  End;
  { colonne droite }
  If (Tab<>1) Or PartOk Then Begin
   If Tab=1 Then PP:=@Parts[PI].PP
   Else If Tab=2 Then PP:=@Trk[Tk].PP Else PP:=@ArrPP;
   For K:=0 To 6 Do Begin
    Y:=Y0+K*26;
    PText(X1+290,Y+4,PLbl[K]);
    Case K Of
     0: S:=IntStr(PP^.Trans);
     1: S:=IntStr(PP^.Vel);
     2: S:=IntStr(PP^.Dly);
     3: S:=IntStr(PP^.LenP)+'%';
     4: S:=IntStr(PP^.Comp);
     5: S:=PrgStr(PP^.Prg);
     6: S:=PrgStr(PP^.Vol);
    End;
    ValBox(X1+400,Y,X1+480,Y+16,S,False);
    ItmAdd(20+K,X1+400,Y,X1+480,Y+16);
   End;
  End;
  Button(X2-120,Y2-34,X2-14,Y2-10,'EXIT',False,True);ItmAdd(50,X2-120,Y2-34,X2-14,Y2-10);
  ShowMouse;
 End;

Begin
 X1:=70;Y1:=46;X2:=570;Y2:=410;
 Tk:=CurTrk;
 If (View<>V_ARR) And (EdPart>=1) Then PI:=EdPart Else PI:=FirstSelPart;
 If PI>0 Then Tab:=1 Else Tab:=2;
 If (PI>0) And (View<>V_ARR) Then Tk:=Parts[PI].Trk;
 Done:=False;Redraw:=True;
 SaveUndo;
 Repeat
  If Redraw Then Begin Draw;Redraw:=False;End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   If (E.Key=K_ESC) Or (E.Key=K_ENTER) Then Done:=True;
  End Else If E.Kind=2 Then Begin
   Right:=((E.B And 2)<>0) And ((E.B And 1)=0);
   Id:=ItmAt(E.X,E.Y);
   If InBox(E.X,E.Y,X1+2,Y1+2,X1+TB_H+2,Y1+TB_H+2) Then Done:=True;
   Case Id Of
    1,2,3: Begin Tab:=Id;Redraw:=True;End;
    10: Begin
         If Tab=1 Then S:=Parts[PI].Name Else S:=Trk[Tk].Name;
         If InputBox('PLAY PARAMETER','Name',S,12) Then Begin
          If Tab=1 Then Parts[PI].Name:=Copy(S,1,12) Else Trk[Tk].Name:=Copy(S,1,12);
         End;
         Redraw:=True;
        End;
    11: Begin
         LstN:=NINST;
         For I:=1 To NINST Do LstItem[I]:=InstName[I];
         I:=ChooseBox(T3('Instrument','Instrument','Instrument'),1);
         If I>0 Then Begin
          Trk[Tk].Instr:=InstName[I];
          Trk[Tk].Drum:=(I=NINST);
          If Trk[Tk].Drum Then Trk[Tk].Chan:=10;
         End;
         Redraw:=True;
        End;
    12: Begin
         V:=Trk[Tk].Chan;
         If AskNum('PLAY PARAMETER','CHANNEL (1-16)',V,1,16) Then Trk[Tk].Chan:=V;
         Redraw:=True;
        End;
    13: Begin Trk[Tk].Outp:=(Trk[Tk].Outp+1) Mod 3;Redraw:=True;End;
    14: Begin CmdDrumMap;Redraw:=True;End;
    15: Begin Trk[Tk].Drum:=Not Trk[Tk].Drum;Redraw:=True;End;
    16: Begin
         S:=PosStr(Parts[PI].Start);
         While (S<>'') And (S[1]=' ') Do Delete(S,1,1);
         If InputBox('START','bar.beat.tick',S,14) Then
          If ParsePos(S,T) And (T<Parts[PI].Stop) Then Parts[PI].Start:=T;
         Redraw:=True;
        End;
    17: Begin
         S:=PosStr(Parts[PI].Stop);
         While (S<>'') And (S[1]=' ') Do Delete(S,1,1);
         If InputBox('END','bar.beat.tick',S,14) Then
          If ParsePos(S,T) And (T>Parts[PI].Start) Then Parts[PI].Stop:=T;
         Redraw:=True;
        End;
    18: Begin Parts[PI].Mute:=Not Parts[PI].Mute;Redraw:=True;End;
    20..26: Begin
         If Tab=1 Then PP:=@Parts[PI].PP
         Else If Tab=2 Then PP:=@Trk[Tk].PP Else PP:=@ArrPP;
         I:=Id-20;
         If Right Then Begin
          Case I Of
           0: PP^.Trans:=0; 1: PP^.Vel:=0; 2: PP^.Dly:=0; 3: PP^.LenP:=100;
           4: PP^.Comp:=0; 5: PP^.Prg:=-1; 6: PP^.Vol:=-1;
          End;
         End Else Begin
          Case I Of
           0: V:=PP^.Trans; 1: V:=PP^.Vel; 2: V:=PP^.Dly; 3: V:=PP^.LenP;
           4: V:=PP^.Comp; 5: V:=PP^.Prg; 6: V:=PP^.Vol;
          Else V:=0;
          End;
          Ok:=False;
          Case I Of
           0: Ok:=AskNum(PLbl[0],'-127..127',V,-127,127);
           1: Ok:=AskNum(PLbl[1],'-127..127',V,-127,127);
           2: Ok:=AskNum(PLbl[2],'ticks',V,-960,960);
           3: Ok:=AskNum(PLbl[3],'%',V,1,400);
           4: Ok:=AskNum(PLbl[4],'-100..100',V,-100,100);
           5: Ok:=AskNum(PLbl[5],'-1 = OFF, 0..127',V,-1,127);
           6: Ok:=AskNum(PLbl[6],'-1 = OFF, 0..127',V,-1,127);
          End;
          If Ok Then
           Case I Of
            0: PP^.Trans:=V; 1: PP^.Vel:=V; 2: PP^.Dly:=V; 3: PP^.LenP:=V;
            4: PP^.Comp:=V; 5: PP^.Prg:=V; 6: PP^.Vol:=V;
           End;
         End;
         Redraw:=True;
        End;
    30..35: Begin
         Trk[Tk].Filt:=Trk[Tk].Filt Xor (1 Shl (Id-30));
         Redraw:=True;
        End;
    50: Done:=True;
   End;
  End;
 Until Done;
 Modified:=True;
 NeedDraw:=True;
End;

{ ---- processeur d'effets MIDI ---- }

Procedure DlgMidiProc;
Const
 MLbl : Array[1..6] Of String[9] = ('REPEAT','ECHO','QUANTIZE','ECHO DEC','VEL DEC','NOTE DEC');
 MLo  : Array[1..6] Of Integer = (0,0,0,-12,-30,-12);
 MHi  : Array[1..6] Of Integer = (16,48,NQUA,12,30,12);
Var X1,Y1,X2,Y2,I,Drag,TopY,BotY,SX: Integer; E: TEvent; Done,Redraw: Boolean;
 Vals: Array[1..6] Of Integer; V: LongInt; S: String;

 Function SlX(K: Integer): Integer;
 Begin
  SlX:=X1+48+(K-1)*68;
 End;

 Function ValOfY(K,Y: Integer): Integer;
 Var R: LongInt;
 Begin
  R:=BotY-Y;
  If R<0 Then R:=0;
  If R>BotY-TopY Then R:=BotY-TopY;
  ValOfY:=MLo[K]+Integer((R*(MHi[K]-MLo[K])+(BotY-TopY) Div 2) Div (BotY-TopY));
 End;

 Procedure Draw;
 Var K,Hy: Integer;
 Begin
  HideMouse;
  DlgBox(X1,Y1,X2,Y2,'MIDI EFFECT PROCESSOR',False);
  For K:=1 To 6 Do Begin
   SX:=SlX(K);
   ValBox(SX-14,Y1+TB_H+8,SX+14,Y1+TB_H+26,IntStr(Vals[K]),False);
   Frame(SX-3,TopY,SX+3,BotY+4);
   Hy:=BotY-((Vals[K]-MLo[K])*(BotY-TopY)) Div (MHi[K]-MLo[K]);
   Box(SX-10,Hy-6,SX+10,Hy+6,PAPER);Frame(SX-10,Hy-6,SX+10,Hy+6);
   Line(SX-10,Hy,SX+10,Hy);
   PText(SX-Length(MLbl[K])*4,BotY+14,MLbl[K]);
  End;
  PText(X1+14,Y2-52,'INPUT');ValBox(X1+60,Y2-56,X1+120,Y2-40,OutLbl[0],False);
  PText(X1+130,Y2-52,'OUTPUT');ValBox(X1+190,Y2-56,X1+250,Y2-40,OutLbl[0],False);
  PText(X1+262,Y2-52,'CHN');
  If MpChan=0 Then S:='TRK' Else S:=IntStr(MpChan);
  ValBox(X1+296,Y2-56,X1+336,Y2-40,S,False);
  PText(X1+14,Y2-28,'STATUS');
  If MpOn Then S:='ON' Else S:='OFF';
  ValBox(X1+72,Y2-32,X1+122,Y2-16,S,MpOn);
  Button(X2-120,Y2-34,X2-14,Y2-10,'EXIT',False,True);
  ShowMouse;
 End;

Begin
 X1:=110;Y1:=60;X2:=530;Y2:=380;
 TopY:=Y1+TB_H+44;BotY:=TopY+130;
 Vals[1]:=MpRep;Vals[2]:=MpEcho;Vals[3]:=MpQuant;Vals[4]:=MpEDec;Vals[5]:=MpVDec;
 Vals[6]:=MpNDec;
 Done:=False;Redraw:=True;Drag:=0;
 Repeat
  If Redraw Then Begin Draw;Redraw:=False;End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   If (E.Key=K_ESC) Or (E.Key=K_ENTER) Then Done:=True;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X1+2,Y1+2,X1+TB_H+2,Y1+TB_H+2) Or
      InBox(E.X,E.Y,X2-120,Y2-34,X2-14,Y2-10) Then Done:=True
   Else If InBox(E.X,E.Y,X1+72,Y2-32,X1+122,Y2-16) Then Begin
    MpOn:=Not MpOn;Redraw:=True;End
   Else If InBox(E.X,E.Y,X1+296,Y2-56,X1+336,Y2-40) Then Begin
    MpChan:=(MpChan+1) Mod 17;Redraw:=True;End
   Else Begin
    For I:=1 To 6 Do Begin
     If InBox(E.X,E.Y,SlX(I)-16,TopY-8,SlX(I)+16,BotY+8) Then Begin
      Drag:=I;Vals[I]:=ValOfY(I,E.Y);Redraw:=True;
     End;
     If InBox(E.X,E.Y,SlX(I)-14,Y1+TB_H+8,SlX(I)+14,Y1+TB_H+26) Then Begin
      V:=Vals[I];
      If AskNum('MIDI PROCESSOR',MLbl[I],V,MLo[I],MHi[I]) Then Vals[I]:=V;
      Redraw:=True;
     End;
    End;
   End;
  End Else If E.Kind=4 Then Begin
   If (Drag>0) And ((E.B And 1)<>0) Then Begin
    Vals[Drag]:=ValOfY(Drag,E.Y);Redraw:=True;
   End;
  End Else If E.Kind=3 Then Drag:=0;
 Until Done;
 MpRep:=Vals[1];MpEcho:=Vals[2];MpQuant:=Vals[3];MpEDec:=Vals[4];
 MpVDec:=Vals[5];MpNDec:=Vals[6];
 NeedDraw:=True;
End;

{ ---- options ---- }

Procedure CmdRecordOpt;
Var Q: String; I: Integer;
Begin
 OLbl[1]:=T3('Count-in bars','Mesures de pr'#130'comptage','Vorz'#132'hler (Takte)');
 OOpt[1]:='#0..4';OVal[1]:=CountIn;
 OLbl[2]:=T3('Auto quantize','Quantif. auto','Auto-Quantisierung');
 Q:='';
 For I:=0 To NQUA Do Begin
  If I>0 Then Q:=Q+'|';
  Q:=Q+QuaLbl[I];
 End;
 OOpt[2]:=Q;OVal[2]:=AutoQ;
 OLbl[3]:=T3('Record mode','Mode d''enregistr.','Aufnahmemodus');
 OOpt[3]:='OVERDUB|REPLACE';OVal[3]:=1-B2B(FlOverdub);
 OLbl[4]:=T3('Punch in/out','Punch in/out','Punch In/Out');
 OOpt[4]:='OFF|ON';OVal[4]:=B2B(FlPunch);
 OLbl[5]:=T3('MIDI thru','MIDI thru','MIDI Thru');
 OOpt[5]:='OFF|ON';OVal[5]:=B2B(FlThru);
 OLbl[6]:=T3('Cycle mode','Mode cycle','Zyklus-Modus');
 OOpt[6]:='MIX|OVERWRITE|STACK';OVal[6]:=CycMode;
 If OptBox('RECORD',6) Then Begin
  CountIn:=OVal[1];AutoQ:=OVal[2];FlOverdub:=(OVal[3]=0);FlPunch:=(OVal[4]=1);
  FlThru:=(OVal[5]=1);CycMode:=OVal[6];
 End;
 NeedDraw:=True;
End;

Procedure CmdPartApp;
Var Q: String; I: Integer;
Begin
 OLbl[1]:=T3('Arrange zoom','Zoom arrangement','Arrange-Zoom');
 OOpt[1]:='#1..6';OVal[1]:=ZoomI;
 OLbl[2]:=T3('Editor zoom','Zoom '#130'diteurs','Editor-Zoom');
 OOpt[2]:='#1..6';OVal[2]:=EdZoom;
 OLbl[3]:='SNAP';
 Q:='';
 For I:=0 To NSNAP-1 Do Begin
  If I>0 Then Q:=Q+'|';
  Q:=Q+SnapLbl[I];
 End;
 OOpt[3]:=Q;OVal[3]:=SnapI;
 OLbl[4]:=T3('Follow song','Suivre le morceau','Song folgen');
 OOpt[4]:='OFF|ON';OVal[4]:=B2B(FlFollow);
 If OptBox('PART APPEARANCE',4) Then Begin
  ZoomI:=OVal[1];EdZoom:=OVal[2];SnapI:=OVal[3];FlFollow:=(OVal[4]=1);
 End;
 NeedDraw:=True;
End;

Procedure CmdOutDev;
Begin
 AllNotesOff;
 LstN:=3;
 {$IFDEF MSWINDOWS}
 LstItem[1]:='Windows (waveOut)';
 {$ELSE}
 LstItem[1]:=T3('PC speaker','Haut-parleur PC','PC-Lautsprecher');
 {$ENDIF}
 LstItem[2]:='MPU-401 (DOS)';
 LstItem[3]:=T3('None','Aucune','Keine');
 OutDev:=Integer(Max2(0,ChooseBox(T3('MIDI output','Sortie MIDI','MIDI-Ausgang'),OutDev+1)-1));
 {$IFDEF FPC}
 If OutDev=1 Then Begin
  OutDev:=0;
  Info('MPU-401 is only available under DOS.','MPU-401 disponible seulement sous DOS.',
    'MPU-401 nur unter DOS verf'#129'gbar.');
 End;
 {$IFDEF MSWINDOWS}
 If OutDev=0 Then Begin
  If Not SynthStart Then Begin
   OutDev:=2;
   Info('Cannot open the Windows audio device.','Ouverture de la carte audio Windows impossible.',
     'Windows-Audioger'#132't nicht verf'#129'gbar.');
  End;
 End Else SynthStop;
 {$ENDIF}
 {$ELSE}
 If OutDev=1 Then MpuInit;
 {$ENDIF}
 NeedDraw:=True;
End;

Procedure CmdMidiDef;
Begin
 OLbl[1]:=T3('Input channel','Canal d''entr'#130'e','Eingangskanal');
 OOpt[1]:='#0..16';OVal[1]:=MidiInChan;
 OLbl[2]:=T3('Default velocity','V'#130'locit'#130' par d'#130'faut','Standard-Velocity');
 OOpt[2]:='#1..127';OVal[2]:=DefVel;
 OLbl[3]:='MIDI thru';
 OOpt[3]:='OFF|ON';OVal[3]:=B2B(FlThru);
 OLbl[4]:=T3('Keyboard octave','Octave du clavier','Tastatur-Oktave');
 OOpt[4]:='#0..8';OVal[4]:=Oct;
 If OptBox('MIDI DEFINITION',4) Then Begin
  MidiInChan:=OVal[1];DefVel:=OVal[2];FlThru:=(OVal[3]=1);Oct:=OVal[4];
 End;
 NeedDraw:=True;
 CmdOutDev;
End;

Procedure CmdMetronome;
Begin
 OLbl[1]:='CLICK';OOpt[1]:='OFF|ON';OVal[1]:=B2B(FlClick);
 OLbl[2]:=T3('Click mode','Mode du click','Klick-Modus');
 OOpt[2]:='ALWAYS|REC ONLY|PLAY ONLY';OVal[2]:=ClickMode;
 OLbl[3]:=T3('Count-in bars','Mesures de pr'#130'comptage','Vorz'#132'hler (Takte)');
 OOpt[3]:='#0..4';OVal[3]:=CountIn;
 OLbl[4]:=T3('Accent note','Note d''accent','Akzent-Note');OOpt[4]:='#0..127';OVal[4]:=ClkHi;
 OLbl[5]:=T3('Beat note','Note de temps','Schlag-Note');OOpt[5]:='#0..127';OVal[5]:=ClkLo;
 OLbl[6]:='Velocity';OOpt[6]:='#1..117';OVal[6]:=ClkVel;
 OLbl[7]:=T3('MIDI channel','Canal MIDI','MIDI-Kanal');OOpt[7]:='#1..16';OVal[7]:=ClkChan;
 If OptBox('METRONOME',7) Then Begin
  FlClick:=(OVal[1]=1);ClickMode:=OVal[2];CountIn:=OVal[3];ClkHi:=OVal[4];
  ClkLo:=OVal[5];ClkVel:=OVal[6];ClkChan:=OVal[7];
 End;
 NeedDraw:=True;
End;

Procedure CmdSyncOpt;
Begin
 OLbl[1]:='SYNC';OOpt[1]:='INTERNAL|MIDI|SMPTE';OVal[1]:=SyncMode;
 OLbl[2]:='Sync delay';OOpt[2]:='#-999..999';OVal[2]:=SyncDel;
 OLbl[3]:='Master tempo';OOpt[3]:='OFF|ON';OVal[3]:=B2B(FlMaster);
 If OptBox('SYNCHRONIZATION',3) Then Begin
  SyncMode:=OVal[1];SyncDel:=OVal[2];FlMaster:=(OVal[3]=1);
 End;
 NeedDraw:=True;
End;

Procedure CmdHuman;
Begin
 OLbl[1]:=T3('Velocity range','Variation velocity','Velocity-Bereich');
 OOpt[1]:='#0..40';OVal[1]:=HumVel;
 OLbl[2]:=T3('Length range %','Variation dur'#130'e %','L'#132'ngen-Bereich %');
 OOpt[2]:='#0..50';OVal[2]:=HumLen;
 If OptBox('HUMAN SYNC',2) Then Begin HumVel:=OVal[1];HumLen:=OVal[2];End;
 NeedDraw:=True;
End;

Procedure CmdRemote;
Begin
 OLbl[1]:='REMOTE';OOpt[1]:='OFF|ON';OVal[1]:=B2B(RemOn<>0);
 OLbl[2]:='START note';OOpt[2]:='#0..127';OVal[2]:=RemStart;
 OLbl[3]:='STOP note';OOpt[3]:='#0..127';OVal[3]:=RemStop;
 If OptBox('REMOTE CONTROL',3) Then Begin
  RemOn:=OVal[1];RemStart:=OVal[2];RemStop:=OVal[3];
 End;
 NeedDraw:=True;
End;

Procedure CmdResetDev;
Begin
 ResetDevices;
 Info('Devices reset.','P'#130'riph'#130'riques r'#130'initialis'#130's.',
      'Ger'#132'te zur'#129'ckgesetzt.');
End;

Procedure CmdLanguage;
Begin
 LstN:=3;
 LstItem[1]:='English';LstItem[2]:='Fran'#135'ais';LstItem[3]:='Deutsch';
 Lang:=Integer(Max2(0,ChooseBox('Language / Langue / Sprache',Lang+1)-1));
 NeedDraw:=True;
End;

{ ---- fenetres d'edition ---- }

Procedure EditOpen(P: Integer; V: Integer);
Var I: Integer;
Begin
 If (View<>V_ARR) And (EdPart>=1) Then Begin View:=V;NeedDraw:=True;Exit;End;
 SaveUndo;
 EdPart:=P;
 EdBakCnt:=Parts[P].Cnt;EdBakStart:=Parts[P].Start;EdBakStop:=Parts[P].Stop;
 EdBakEv:=Nil;
 If EdBakCnt>0 Then Begin
  GetMem(EdBakEv,EdBakCnt*SizeOf(TEvt));
  Move(Parts[P].Ev^,EdBakEv^,EdBakCnt*SizeOf(TEvt));
 End;
 EdT0:=FloorDiv(Parts[P].Start,BarTicks)*BarTicks;
 ListTop:=1;ListSel:=0;
 EdTop:=84;
 If Parts[P].Cnt>0 Then Begin
  I:=1;
  While (I<=Parts[P].Cnt) And (Parts[P].Ev^[I].Kind<>EK_NOTE) Do Inc(I);
  If I<=Parts[P].Cnt Then EdTop:=Parts[P].Ev^[I].D1+20;
  If EdTop>127 Then EdTop:=127;
  If EdTop<KVIS Then EdTop:=KVIS;
 End;
 View:=V;
 NeedDraw:=True;
End;

Procedure EditClose(Keep: Boolean);
Var I: Integer; Chg: Boolean;
Begin
 If (EdPart>=1) And Parts[EdPart].Used Then Begin
  If Not Keep Then Begin
   For I:=Parts[EdPart].Cnt DownTo 1 Do EvDel(EdPart,I);
   For I:=1 To EdBakCnt Do
    EvAdd(EdPart,EdBakEv^[I].T,EdBakEv^[I].Len,EdBakEv^[I].Kind,
          EdBakEv^[I].D1,EdBakEv^[I].D2);
   Parts[EdPart].Start:=EdBakStart;Parts[EdPart].Stop:=EdBakStop;
  End Else Begin
   Chg:=(Parts[EdPart].Cnt<>EdBakCnt) Or (Parts[EdPart].Start<>EdBakStart) Or
        (Parts[EdPart].Stop<>EdBakStop);
   For I:=1 To Parts[EdPart].Cnt Do Begin
    Parts[EdPart].Ev^[I].Sel:=False;
    If Not Chg Then
     If (Parts[EdPart].Ev^[I].T<>EdBakEv^[I].T) Or (Parts[EdPart].Ev^[I].Len<>EdBakEv^[I].Len)
        Or (Parts[EdPart].Ev^[I].D1<>EdBakEv^[I].D1) Or
        (Parts[EdPart].Ev^[I].D2<>EdBakEv^[I].D2) Or
        (Parts[EdPart].Ev^[I].Kind<>EdBakEv^[I].Kind) Then Chg:=True;
   End;
   If Chg Then Modified:=True;
  End;
 End;
 If EdBakEv<>Nil Then FreeMem(EdBakEv,EdBakCnt*SizeOf(TEvt));
 EdBakEv:=Nil;EdBakCnt:=0;
 EdPart:=0;View:=V_ARR;
 NeedDraw:=True;
End;

Procedure CmdSetView(V: Integer);
Var P: Integer;
Begin
 If V=V_ARR Then Begin
  If View<>V_ARR Then Begin
   If EdPart>0 Then EditClose(True) Else Begin View:=V_ARR;NeedDraw:=True;End;
  End;
  Exit;
 End;
 If V=V_MASTER Then Begin
  If EdPart>0 Then EditClose(True);
  View:=V_MASTER;
  EdT0:=0;MstTop:=1;MstSel:=0;
  If NTemp=0 Then TempoSet(0,TempoFix);
  NeedDraw:=True;
  Exit;
 End;
 If (View<>V_ARR) And (EdPart>0) Then Begin View:=V;NeedDraw:=True;Exit;End;
 P:=FirstSelPart;
 If P=0 Then P:=PartAt(CurTrk,CurPos);
 If P=0 Then Begin
  Info('Select a part to edit (double-click it).',
       'S'#130'lectionnez une partie '#133' '#130'diter (double-clic).',
       'W'#132'hlen Sie einen Part zum Bearbeiten (Doppelklick).');
  Exit;
 End;
 EditOpen(P,V);
End;

Procedure CmdEditPart;
Begin
 CmdSetView(V_KEY);
End;

Procedure CmdMidiProc;
Begin
 DlgMidiProc;
End;


{ ====================================================================== }
{                         MENUS DEROULANTS                               }
{ ====================================================================== }

Const
 NMENU = 7;
 MTitle : Array[1..NMENU] Of String[40] =
  ('Desk~Bureau~Desk','File~Fichier~Datei','Edit~Edition~Bearbeiten',
   'Structure~Structure~Struktur','Functions~Fonctions~Funktionen',
   'Options~Options~Optionen','Windows~Fen'#136'tres~Fenster');

Var
 MenuOpen,MenuHi : Integer;

Function MCount(M: Integer): Integer;
Begin
 Case M Of
  1: MCount:=5;
  2: MCount:=11;
  3: MCount:=13;
  4: MCount:=11;
  5: MCount:=13;
  6: MCount:=18;
  7: MCount:=9;
 Else MCount:=0;
 End;
End;

{ 'EN~FR~DE|raccourci' ; '-' = separateur }
Function MItem(M,I: Integer): String;
Begin
 MItem:='';
 Case M Of
  1: Case I Of
      1: MItem:='About Cubase...~A propos de Cubase...~'#154'ber Cubase...';
      2: MItem:='-';
      3: MItem:='Free memory~M'#130'moire libre~Freier Speicher';
      4: MItem:='Hardcopy (PBM)~Copie d'''#130'cran (PBM)~Bildschirmkopie (PBM)';
      5: MItem:='Help~Aide~Hilfe|F11';
     End;
  2: Case I Of
      1: MItem:='New arrangement~Nouvel arrangement~Neues Arrangement|^N';
      2: MItem:='Open arrangement...~Ouvrir un arrangement...~Arrangement '#148'ffnen...|^O';
      3: MItem:='Save arrangement~Sauver l''arrangement~Arrangement speichern|^S';
      4: MItem:='Save as...~Sauver sous...~Speichern unter...';
      5: MItem:='-';
      6: MItem:='Import MIDI file...~Importer fichier MIDI...~MIDI-Datei importieren...';
      7: MItem:='Export MIDI file...~Exporter fichier MIDI...~MIDI-Datei exportieren...';
      8: MItem:='-';
      9: MItem:='Demo song~Morceau de d'#130'mo~Demo-Lied';
      10: MItem:='-';
      11: MItem:='Quit~Quitter~Beenden|^Q';
     End;
  3: Case I Of
      1: MItem:='Undo~Annuler~R'#129'ckg'#132'ngig|^Z';
      2: MItem:='-';
      3: MItem:='Cut~Couper~Ausschneiden|^X';
      4: MItem:='Copy~Copier~Kopieren|^C';
      5: MItem:='Paste~Coller~Einf'#129'gen|^V';
      6: MItem:='Delete~Effacer~L'#148'schen|Del';
      7: MItem:='-';
      8: MItem:='Select all~Tout s'#130'lectionner~Alles w'#132'hlen|^A';
      9: MItem:='Deselect all~Tout d'#130's'#130'lectionner~Nichts w'#132'hlen';
      10: MItem:='-';
      11: MItem:='Edit part...~Editer la partie...~Part bearbeiten...|Enter';
      12: MItem:='Rename part...~Renommer la partie...~Part umbenennen...';
      13: MItem:='Rename track...~Renommer la piste...~Spur umbenennen...';
     End;
  4: Case I Of
      1: MItem:='Create part~Cr'#130'er une partie~Part erzeugen';
      2: MItem:='Split part~Couper la partie~Part teilen';
      3: MItem:='Glue parts~Coller les parties~Parts verkleben';
      4: MItem:='Repeat parts...~R'#130'p'#130'ter les parties...~Parts wiederholen...';
      5: MItem:='-';
      6: MItem:='Fit part to locators~Ajuster aux locators~An Locatoren anpassen';
      7: MItem:='Move part to position~Placer '#133' la position~Zur Position schieben';
      8: MItem:='Mute / unmute part~Muet / actif~Part stumm / aktiv';
      9: MItem:='-';
      10: MItem:='Insert bars...~Ins'#130'rer des mesures...~Takte einf'#129'gen...';
      11: MItem:='Delete bars...~Supprimer des mesures...~Takte l'#148'schen...';
     End;
  5: Case I Of
      1: MItem:='Quantize~Quantifier~Quantisieren';
      2: MItem:='Over quantize~Sur-quantifier~Overquantisieren';
      3: MItem:='-';
      4: MItem:='Transpose...~Transposer...~Transponieren...';
      5: MItem:='Velocity +/-...~V'#130'locit'#130' +/-...~Velocity +/-...';
      6: MItem:='Velocity %...~V'#130'locit'#130' %...~Velocity %...';
      7: MItem:='Fixed length...~Longueur fixe...~Feste L'#132'nge...';
      8: MItem:='Legato~L'#130'gato~Legato';
      9: MItem:='Delete doubles~Effacer les doublons~Doppelte l'#148'schen';
      10: MItem:='Delete controllers~Effacer les contr'#147'leurs~Controller l'#148'schen';
      11: MItem:='Thin out controllers...~All'#130'ger les contr'#147'leurs...~Controller ausd'#129'nnen...';
      12: MItem:='-';
      13: MItem:='Logical edit...~Edition logique...~Logischer Editor...';
     End;
  6: Case I Of
      1: MItem:='Chase events~Poursuite des '#130'v'#130'nements~Chase Events';
      2: MItem:='Follow Song~Suivre le morceau~Song folgen';
      3: MItem:='Reset on Stop~Reset '#133' l''arr'#136't~Reset bei Stop';
      4: MItem:='Tempo Recording~Enreg. du tempo~Tempo-Aufnahme';
      5: MItem:='-';
      6: MItem:='Record...~Enregistrement...~Aufnahme...';
      7: MItem:='Part Appearance...~Aspect des parties...~Part-Darstellung...';
      8: MItem:='MIDI Definition...~D'#130'finition MIDI...~MIDI-Definition...';
      9: MItem:='Metronome...~M'#130'tronome...~Metronom...';
      10: MItem:='Synchronization...~Synchronisation...~Synchronisation...';
      11: MItem:='Human Sync...~Human Sync...~Human Sync...';
      12: MItem:='Remote Control...~T'#130'l'#130'commande...~Fernsteuerung...';
      13: MItem:='MIDI Processor...~Processeur MIDI...~MIDI-Prozessor...|F8';
      14: MItem:='-';
      15: MItem:='Reset Devices~R'#130'init. p'#130'riph'#130'riques~Ger'#132'te zur'#129'cksetzen';
      16: MItem:='-';
      17: MItem:='Language...~Langue...~Sprache...';
      18: MItem:='Save options~Sauver les options~Optionen speichern';
     End;
  7: Case I Of
      1: MItem:='Arrange~Arrangement~Arrange|F1';
      2: MItem:='Key Edit~Key Edit~Key Edit|F2';
      3: MItem:='Score Edit~Partition~Partitur|F3';
      4: MItem:='Grid Edit~Grille~Grid Edit|F4';
      5: MItem:='Drum Edit~Batterie~Drum Edit|F5';
      6: MItem:='Master Track~Piste ma'#136'tre~Master-Spur|F6';
      7: MItem:='-';
      8: MItem:='Play Parameter...~Param. de lecture...~Wiedergabe-Param...|F7';
      9: MItem:='MIDI Processor...~Processeur MIDI...~MIDI-Prozessor...|F8';
     End;
 End;
End;

Function MLabel(M,I: Integer): String;
Var S: String; P: Integer;
Begin
 S:=MItem(M,I);
 If S='-' Then Begin MLabel:='-';Exit;End;
 P:=Pos('|',S);
 If P>0 Then MLabel:=Part3(Copy(S,1,P-1),Lang)+Copy(S,P,40)
 Else MLabel:=Part3(S,Lang);
End;

Function MChecked(M,I: Integer): Boolean;
Begin
 MChecked:=False;
 If M=6 Then
  Case I Of
   1: MChecked:=FlChase;
   2: MChecked:=FlFollow;
   3: MChecked:=FlReset;
   4: MChecked:=FlTempoRec;
  End;
 If M=7 Then If (I>=1) And (I<=6) Then MChecked:=(View=I);
End;

Function MEnabled(M,I: Integer): Boolean;
Begin
 MEnabled:=True;
 If (M=3) And (I=1) Then MEnabled:=UndoValid;
End;

Function MIsSep(M,I: Integer): Boolean;
Begin
 MIsSep:=(MItem(M,I)='-');
End;

Function MT(I: Integer): String;
Begin
 MT:=Part3(MTitle[I],Lang);
End;

Function MenuX(M: Integer): Integer;
Var I,X: Integer;
Begin
 X:=14;
 For I:=1 To M-1 Do X:=X+Length(MT(I))*8+12;
 MenuX:=X;
End;

Function ItemH(M,I: Integer): Integer;
Begin
 If MIsSep(M,I) Then ItemH:=8 Else ItemH:=16;
End;

Procedure DropRect(M: Integer; Var X1,Y1,X2,Y2: Integer);
Var I,W,L,P: Integer; S: String;
Begin
 W:=0;Y2:=MENU_H+2;
 For I:=1 To MCount(M) Do Begin
  S:=MLabel(M,I);
  P:=Pos('|',S);
  If P>0 Then L:=(P-1)*8+24+(Length(S)-P)*8 Else L:=Length(S)*8;
  If L>W Then W:=L;
  Y2:=Y2+ItemH(M,I);
 End;
 X1:=MenuX(M)-6;
 X2:=X1+W+32;
 If X2>SCR_W-4 Then Begin X1:=X1-(X2-(SCR_W-4));X2:=SCR_W-4;End;
 Y1:=MENU_H;
End;

Function ItemY(M,I: Integer): Integer;
Var K,Y: Integer;
Begin
 Y:=MENU_H+2;
 For K:=1 To I-1 Do Y:=Y+ItemH(M,K);
 ItemY:=Y;
End;

Function DropHit(M: Integer; X,Y: LongInt): Integer;
Var X1,Y1,X2,Y2,I: Integer;
Begin
 DropHit:=0;
 DropRect(M,X1,Y1,X2,Y2);
 If Not InBox(X,Y,X1,Y1,X2,Y2) Then Exit;
 For I:=1 To MCount(M) Do
  If (Y>=ItemY(M,I)) And (Y<ItemY(M,I)+ItemH(M,I)) Then DropHit:=I;
End;

Function TitleHit(X,Y: LongInt): Integer;
Var M: Integer;
Begin
 TitleHit:=0;
 If (Y<0) Or (Y>=MENU_H) Then Exit;
 For M:=1 To NMENU Do
  If (X>=MenuX(M)-6) And (X<=MenuX(M)+Length(MT(M))*8+5) Then TitleHit:=M;
End;

Procedure DrawMenuBar;
Var M: Integer;
Begin
 Box(0,0,SCR_W-1,MENU_H-1,PAPER);
 SetColor(INK);
 SetLineStyle(SolidLn,0,1);
 Line(0,MENU_H-1,SCR_W-1,MENU_H-1);
 For M:=1 To NMENU Do Begin
  If M=MenuOpen Then Begin
   Box(MenuX(M)-6,0,MenuX(M)+Length(MT(M))*8+5,MENU_H-2,INK);
   WText(MenuX(M),5,MT(M));
  End Else PText(MenuX(M),5,MT(M));
 End;
End;

Procedure DrawDropDown;
Var X1,Y1,X2,Y2,I,Y,P: Integer; S,Sc,Lb: String; Hi: Boolean;
Begin
 If MenuOpen=0 Then Exit;
 DropRect(MenuOpen,X1,Y1,X2,Y2);
 Box(X1+3,Y1+3,X2+3,Y2+3,INK);
 Box(X1,Y1,X2,Y2,PAPER);
 Frame(X1,Y1,X2,Y2);
 For I:=1 To MCount(MenuOpen) Do Begin
  S:=MLabel(MenuOpen,I);
  Y:=ItemY(MenuOpen,I);
  If S='-' Then Begin
   SetLineStyle(UserBitLn,$AAAA,1);
   SetColor(INK);
   Line(X1+2,Y+3,X2-2,Y+3);
   SetLineStyle(SolidLn,0,1);
  End Else Begin
   P:=Pos('|',S);
   If P>0 Then Begin Lb:=Copy(S,1,P-1);Sc:=Copy(S,P+1,20);End Else Begin
     Lb:=S;Sc:='';End;
   Hi:=(I=MenuHi) And MEnabled(MenuOpen,I);
   If Hi Then Box(X1+1,Y,X2-1,Y+15,INK);
   If MChecked(MenuOpen,I) Then Begin
    If Hi Then WText(X1+4,Y+4,#251) Else PText(X1+4,Y+4,#251);
   End;
   If Not MEnabled(MenuOpen,I) Then Begin
    GreyText(X1+24,Y+4,Lb);
    If Sc<>'' Then GreyText(X2-8-Length(Sc)*8,Y+4,Sc);
   End Else If Hi Then Begin
    WText(X1+24,Y+4,Lb);
    If Sc<>'' Then WText(X2-8-Length(Sc)*8,Y+4,Sc);
   End Else Begin
    PText(X1+24,Y+4,Lb);
    If Sc<>'' Then PText(X2-8-Length(Sc)*8,Y+4,Sc);
   End;
  End;
 End;
End;


Procedure DoMenu(M,I: Integer);
Begin
 Case M Of
  1: Case I Of
      1: CmdAbout;
      3: CmdFreeMem;
      4: HardcopyPBM;
      5: CmdHelp;
     End;
  2: Case I Of
      1: CmdNew;
      2: CmdOpen;
      3: CmdSave;
      4: CmdSaveAs;
      6: CmdImportMidi;
      7: CmdExportMidi;
      9: CmdDemo;
      11: CmdQuit;
     End;
  3: Case I Of
      1: DoUndo;
      3: If View=V_ARR Then CmdCopyParts(True) Else CmdCopyEv(True);
      4: If View=V_ARR Then CmdCopyParts(False) Else CmdCopyEv(False);
      5: If View=V_ARR Then CmdPaste Else CmdPasteEv;
      6: If View=V_ARR Then CmdDeleteParts Else DeleteSelEvents;
      8: CmdSelAll(True);
      9: CmdSelAll(False);
      11: CmdEditPart;
      12: CmdRenamePart;
      13: CmdRenameTrack;
     End;
  4: Case I Of
      1: CmdCreatePart;
      2: CmdSplit;
      3: CmdGlue;
      4: CmdRepeat;
      6: CmdFitLocators;
      7: CmdMovePos;
      8: CmdMuteParts;
      10: CmdInsertBars(True);
      11: CmdInsertBars(False);
     End;
  5: Case I Of
      1: CmdQuantize;
      2: CmdOverQuantize;
      4: CmdTranspose;
      5: CmdVelocity;
      6: CmdVelPct;
      7: CmdFixLen;
      8: ApplyEv(4,0);
      9: ApplyEv(5,0);
      10: ApplyEv(6,0);
      11: CmdThin;
      13: CmdLogical;
     End;
  6: Case I Of
      1: Toggle(FlChase);
      2: Toggle(FlFollow);
      3: Toggle(FlReset);
      4: Toggle(FlTempoRec);
      6: CmdRecordOpt;
      7: CmdPartApp;
      8: CmdMidiDef;
      9: CmdMetronome;
      10: CmdSyncOpt;
      11: CmdHuman;
      12: CmdRemote;
      13: CmdMidiProc;
      15: CmdResetDev;
      17: CmdLanguage;
      18: SaveOptions;
     End;
  7: Case I Of
      1..6: CmdSetView(I);
      8: DlgPlayParam;
      9: CmdMidiProc;
     End;
 End;
End;

Function NextItem(M,From,Dir: Integer): Integer;
Var I,N: Integer;
Begin
 N:=MCount(M);
 I:=From;
 Repeat
  I:=I+Dir;
  If I<1 Then I:=N;
  If I>N Then I:=1;
  If (Not MIsSep(M,I)) And MEnabled(M,I) Then Begin
    NextItem:=I;Exit;End;
 Until I=From;
 NextItem:=From;
End;

Procedure RunMenu(StartM: Integer; ByMouse: Boolean);
Var M,Hi,H,T: Integer; E: TEvent; Done,Pick,Redraw: Boolean;
Begin
 M:=StartM;Hi:=0;
 If Not ByMouse Then Hi:=NextItem(M,0,1);
 MenuOpen:=M;MenuHi:=Hi;
 DrawAll;
 Done:=False;Pick:=False;
 Repeat
  PollEvent(E);
  Redraw:=False;
  Case E.Kind Of
   4,2: Begin
         T:=TitleHit(E.X,E.Y);
         If (T>0) And (T<>M) Then Begin M:=T;Hi:=0;Redraw:=True;End
         Else Begin
          H:=DropHit(M,E.X,E.Y);
          If (H<>0) And (MIsSep(M,H) Or Not MEnabled(M,H)) Then H:=0;
          If H<>Hi Then Begin Hi:=H;Redraw:=True;End;
         End;
         If E.Kind=2 Then Begin
          If DropHit(M,E.X,E.Y)=0 Then Begin
           If TitleHit(E.X,E.Y)=0 Then Done:=True;
          End Else If Hi<>0 Then Begin Pick:=True;Done:=True;End;
         End;
        End;
   3: Begin
       H:=DropHit(M,E.X,E.Y);
       If (H<>0) And (Hi=H) Then Begin Pick:=True;Done:=True;End;
      End;
   1: Case E.Key Of
       K_ESC: Done:=True;
       K_LEFT: Begin Dec(M);If M<1 Then
         M:=NMENU;Hi:=NextItem(M,0,1);Redraw:=True;End;
       K_RIGHT: Begin Inc(M);If M>NMENU Then
         M:=1;Hi:=NextItem(M,0,1);Redraw:=True;End;
       K_UP: Begin Hi:=NextItem(M,Hi,-1);Redraw:=True;End;
       K_DOWN: Begin Hi:=NextItem(M,Hi,1);Redraw:=True;End;
       K_ENTER: If Hi<>0 Then Begin Pick:=True;Done:=True;End;
      End;
  End;
  If Redraw Then Begin MenuOpen:=M;MenuHi:=Hi;DrawAll;End;
 Until Done;
 MenuOpen:=0;MenuHi:=0;
 DrawAll;
 If Pick And (Hi>0) Then DoMenu(M,Hi);
End;

{ ====================================================================== }
{                  SOURIS / CLAVIER : GESTION DES VUES                   }
{ ====================================================================== }

Var
 LastClkCs  : LongInt;
 LastClkId  : Integer;
 DragKind   : Integer;
 DragP,DragX0,DragY0,DragTrk0 : Integer;
 DragT0 : LongInt;
 OrigS      : Array[1..MAXPART] Of LongInt;
 OrigTk     : Array[1..MAXPART] Of Byte;
 OrigEvT    : Array[1..MAXEV] Of LongInt;
 OrigEvP    : Array[1..MAXEV] Of Byte;
 OrigEvL    : Array[1..MAXEV] Of LongInt;
 RbX1,RbY1,RbX2,RbY2 : Integer;
 RbOn       : Boolean;
 DragMoved  : Boolean;

Function DblClick(Id: Integer): Boolean;
Var N: LongInt;
Begin
 N:=NowCs;
 DblClick:=(LastClkId=Id) And (Abs(N-LastClkCs)<45);
 LastClkId:=Id;LastClkCs:=N;
 If DblClick Then LastClkId:=-1;
End;

Procedure PreviewNote(Pitch,Vel: Integer);
Var Tk: Integer;
Begin
 Tk:=PartTrk;
 {$IFDEF MSWINDOWS}
 ChanTimbre[Trk[Tk].Chan]:=TimbreOf(Trk[Tk].Instr);
 {$ENDIF}
 SndOn(Trk[Tk].Outp,Trk[Tk].Chan,Pitch,Vel,NowCs+25,True);
End;

Procedure XorRect(X1,Y1,X2,Y2: Integer);
Begin
 HideMouse;
 SetWriteMode(XORPut);
 SetColor(15);SetLineStyle(SolidLn,0,1);
 Rectangle(X1,Y1,X2,Y2);
 SetWriteMode(NormalPut);
 ShowMouse;
End;

Function ToolCycle(V,Max1: Integer; Btn: LongInt): Integer;
Begin
 If (Btn And 2)<>0 Then Begin Dec(V);If V<1 Then V:=Max1;End
 Else Begin Inc(V);If V>Max1 Then V:=1;End;
 ToolCycle:=V;
End;

Function CycleIdx(V,Lo,Hi: Integer; Btn: LongInt): Integer;
Begin
 If (Btn And 2)<>0 Then Begin Dec(V);If V<Lo Then V:=Hi;End
 Else Begin Inc(V);If V>Hi Then V:=Lo;End;
 CycleIdx:=V;
End;

{ ---- transport ---- }

Procedure TransportClick(X,Y: Integer; Btn: LongInt);
Var A: Boolean;
Begin
 A:=(Y<TR_Y+31);
 If X<=51 Then Begin
  If A Then Begin
   Trk[CurTrk].Solo:=Not Trk[CurTrk].Solo;UpdateSolo;
  End Else FlEdSolo:=Not FlEdSolo;
 End Else If X<=118 Then Begin
  If A Then FlOverdub:=Not FlOverdub Else FlCycle:=Not FlCycle;
 End Else If X<=181 Then Begin
  If A Then FlPunch:=Not FlPunch Else FlMaster:=Not FlMaster;
 End Else If X<=286 Then Begin
  If (Btn And 2)<>0 Then LocFromPos(A) Else CmdSetLoc(A);
 End Else If (X>=288) And (X<=408) Then Begin
  If A Then Begin
   If X<=346 Then CmdRewind Else If X>=350 Then CmdForward;
  End Else Begin
   If X<=326 Then CmdStop Else If (X>=329) And (X<=367) Then CmdStart
   Else If X>=370 Then CmdRecord;
  End;
 End Else If (X>=410) And (X<=515) Then CmdGoto
 Else If (X>=517) And (X<=577) Then Begin
  If A Then CmdSignature Else CmdTempo;
 End Else If X>=579 Then Begin
  If A Then FlClick:=Not FlClick Else CmdSync;
 End;
 NeedDraw:=True;
End;

{ ---- arrangement ---- }

Procedure NewDragSnapshot;
Var I: Integer;
Begin
 For I:=1 To MAXPART Do
  If Parts[I].Used Then Begin
   OrigS[I]:=Parts[I].Start;OrigTk[I]:=Parts[I].Trk;
  End;
End;

Procedure SelectOnly(P: Integer);
Var I: Integer;
Begin
 For I:=1 To MAXPART Do Parts[I].Sel:=False;
 If P>0 Then Parts[P].Sel:=True;
End;

Procedure ArrangeClick(X,Y: Integer; Btn: LongInt);
Var Tk,P,Q,I,NP: Integer; T,NewV: LongInt; XL,XR: Integer; Right: Boolean;
Begin
 Right:=((Btn And 2)<>0) And ((Btn And 1)=0);
 { parametres }
 If (Y>=P1_Y) And (Y<=P1_B) Then Begin
  If (X>=46) And (X<=102) Then SnapI:=CycleIdx(SnapI,0,NSNAP-1,Btn)
  Else If (X>=168) And (X<=250) Then ToolI:=ToolCycle(ToolI,NTOOL,Btn)
  Else If (X>=340) And (X<=388) Then QuaI:=CycleIdx(QuaI,0,NQUA,Btn)
  Else If (X>=490) And (X<=570) Then CycMode:=CycleIdx(CycMode,0,2,Btn)
  Else If (X>=580) And (X<=598) Then Begin If ZoomI>1 Then Dec(ZoomI);End
  Else If (X>=602) And (X<=620) Then Begin If ZoomI<6 Then Inc(ZoomI);End;
  NeedDraw:=True;
  Exit;
 End;
 { regle }
 If (Y>=HD_Y) And (Y<=HD_B) And (X>=AR_X0) And (X<=AR_X1) Then Begin
  XL:=XOfTick(LocL);XR:=XOfTick(LocR);
  If Right Then Begin
   T:=Quant(TickOfX(X),SnapTk);
   If Abs(X-XL)<Abs(X-XR) Then Begin LocL:=T;If LocR<=LocL Then LocR:=LocL+BarTicks;End
   Else Begin LocR:=T;If LocL>=LocR Then LocL:=Max2(0,LocR-BarTicks);End;
   NeedDraw:=True;
  End Else If (Abs(X-XL)<=5) And (Y>=HD_B-8) Then DragKind:=4
  Else If (Abs(X-XR)<=5) And (Y>=HD_B-8) Then DragKind:=5
  Else Begin
   SetPos(Quant(TickOfX(X),SnapTk));
   DragKind:=6;
  End;
  Exit;
 End;
 { ascenseurs }
 If (X>=VS_X) And (Y>=R0_Y) And (Y<=R0_B) Then Begin
  NewV:=ScrollClick(True,VS_X,R0_Y,SCR_W-1,R0_B,X,Y,ArrTop-1,NTRK,VISR);
  If NewV>=0 Then ArrTop:=Integer(NewV)+1 Else DragKind:=10;
  NeedDraw:=True;Exit;
 End;
 If (Y>=HS_Y) And (Y<=HS_B) And (X>=AR_X0) Then Begin
  If X<=AR_X0+15 Then ViewBar:=Max2(0,ViewBar-1)
  Else If X>=SCR_W-16 Then ViewBar:=Min2(999,ViewBar+1)
  Else Begin
   NewV:=ScrollClick(False,AR_X0,HS_Y,SCR_W-1,HS_B,X,Y,ViewBar,1000,VisBars);
   If NewV>=0 Then ViewBar:=NewV Else DragKind:=11;
  End;
  NeedDraw:=True;Exit;
 End;
 Tk:=TrkAtY(Y);
 If Tk=0 Then Exit;
 { liste des pistes }
 If X<LW Then Begin
  If X<14 Then Begin Trk[Tk].Mute:=Not Trk[Tk].Mute;Modified:=True;End
  Else If X<28 Then Begin Trk[Tk].Solo:=Not Trk[Tk].Solo;UpdateSolo;Modified:=True;End
  Else If X<124 Then Begin
   CurTrk:=Tk;
   If DblClick(1000+Tk) Then CmdRenameTrack;
  End Else If X<196 Then Begin
   CurTrk:=Tk;
   LstN:=NINST;
   For I:=1 To NINST Do LstItem[I]:=InstName[I];
   I:=ChooseBox(T3('Instrument','Instrument','Instrument'),1);
   If I>0 Then Begin
    Trk[Tk].Instr:=InstName[I];Trk[Tk].Drum:=(I=NINST);
    If Trk[Tk].Drum Then Trk[Tk].Chan:=10;
    Modified:=True;
   End;
  End Else Begin
   CurTrk:=Tk;
   NewV:=Trk[Tk].Chan;
   If AskNum('CHANNEL','1-16',NewV,1,16) Then Begin Trk[Tk].Chan:=NewV;Modified:=True;End;
  End;
  NeedDraw:=True;
  Exit;
 End;
 { zone des parties }
 If (X<AR_X0) Or (X>AR_X1) Then Exit;
 T:=TickOfX(X);
 CurTrk:=Tk;
 P:=PartAt(Tk,T);
 Case ToolI Of
  1: Begin
      If P>0 Then Begin
       If DblClick(P) Then Begin
        SelectOnly(P);CmdSetView(V_KEY);Exit;
       End;
       If Right Then Begin
        SaveUndo;
        NP:=PartCopy(P);
        If NP>0 Then Begin
         If Not Parts[P].Sel Then SelectOnly(P);
         Parts[NP].Sel:=True;Parts[P].Sel:=False;
         P:=NP;
        End;
       End Else If Not Parts[P].Sel Then SelectOnly(P);
       If Not Right Then SaveUndo;
       NewDragSnapshot;
       DragP:=P;DragX0:=X;DragY0:=Y;DragMoved:=False;
       DragT0:=Parts[P].Start;DragTrk0:=Tk;
       If (XOfTick(Parts[P].Stop)-X<=5) And (XOfTick(Parts[P].Stop)-XOfTick(Parts[P].Start)>12)
          And (SelPartCount=1) Then DragKind:=2
       Else DragKind:=1;
      End Else Begin
       SelectOnly(0);
       DragKind:=0;
      End;
     End;
  2: If P=0 Then Begin
      SaveUndo;
      DragT0:=Quant(T-SnapTk Div 2,SnapTk);
      If SnapI=0 Then DragT0:=FloorDiv(T,BarTicks)*BarTicks;
      If DragT0<0 Then DragT0:=0;
      NP:=PartNew(Tk,DragT0,DragT0+Max2(SnapTk,BarTicks Div 4),Trk[Tk].Name);
      If NP=0 Then Begin
       Info('No more parts available.','Plus de parties disponibles.','Keine Parts mehr frei.');
       Exit;
      End;
      SelectOnly(NP);
      DragP:=NP;DragKind:=3;DragMoved:=True;
      Modified:=True;
     End Else Begin
      SelectOnly(P);
      If DblClick(P) Then CmdSetView(V_KEY);
     End;
  3: If P>0 Then Begin SaveUndo;PartFree(P);Touch;End;
  4: If P>0 Then Begin
      SaveUndo;
      SplitPart(P,Quant(T,SnapTk));
      Touch;
     End;
  5: If P>0 Then Begin
      Q:=NextPartOnTrack(P);
      If Q>0 Then Begin SaveUndo;GlueParts(P,Q);Touch;End;
     End;
  6: If P>0 Then Begin Parts[P].Mute:=Not Parts[P].Mute;Touch;End;
 End;
 NeedDraw:=True;
End;

Procedure ArrangeMove(X,Y: Integer);
Var I,Tk,DTk: Integer; D,T,Nw: LongInt;
Begin
 Case DragKind Of
  1: If DragP>0 Then Begin
      D:=Quant(TickOfX(X)-TickOfX(DragX0),SnapTk);
      Tk:=TrkAtY(Y);
      If Tk=0 Then DTk:=0 Else DTk:=Tk-DragTrk0;
      If (D<>0) Or (DTk<>0) Then DragMoved:=True;
      For I:=1 To MAXPART Do
       If Parts[I].Used And Parts[I].Sel Then Begin
        Nw:=OrigS[I]+D;
        If Nw<0 Then Nw:=0;
        Parts[I].Stop:=Nw+(Parts[I].Stop-Parts[I].Start);
        Parts[I].Start:=Nw;
        Parts[I].Trk:=Integer(Clamp(OrigTk[I]+DTk,1,NTRK));
       End;
      NeedDraw:=True;
     End;
  2,3: If DragP>0 Then Begin
      T:=Quant(TickOfX(X),SnapTk);
      If (DragKind=3) And (SnapI=0) Then T:=Quant(TickOfX(X),BarTicks Div 4);
      If T<=Parts[DragP].Start+Max2(1,SnapTk Div 2) Then
       T:=Parts[DragP].Start+Max2(1,SnapTk);
      Parts[DragP].Stop:=T;DragMoved:=True;
      NeedDraw:=True;
     End;
  4: Begin
      T:=Quant(TickOfX(X),SnapTk);If T<0 Then T:=0;
      If T>=LocR Then T:=LocR-1;
      LocL:=T;NeedDraw:=True;
     End;
  5: Begin
      T:=Quant(TickOfX(X),SnapTk);If T<=LocL Then T:=LocL+1;
      LocR:=T;NeedDraw:=True;
     End;
  6: Begin
      SetPos(Max2(0,Quant(TickOfX(X),SnapTk)));
     End;
  10: Begin
       ArrTop:=Integer(ScrollDrag(True,VS_X,R0_Y,SCR_W-1,R0_B,X,Y,NTRK,VISR))+1;
       NeedDraw:=True;
      End;
  11: Begin
       ViewBar:=ScrollDrag(False,AR_X0,HS_Y,SCR_W-1,HS_B,X,Y,1000,VisBars);
       NeedDraw:=True;
      End;
 End;
End;

{ ====================================================================== }
{                        EDITEURS : SOURIS                               }
{ ====================================================================== }

Function EvX2(P,I: Integer): Integer;
Var X: Integer;
Begin
 X:=XT(Parts[P].Start+Parts[P].Ev^[I].T+Parts[P].Ev^[I].Len)-1;
 If X<XT(Parts[P].Start+Parts[P].Ev^[I].T)+2 Then
  X:=XT(Parts[P].Start+Parts[P].Ev^[I].T)+2;
 EvX2:=X;
End;

Function FindNoteX(X,Pitch: Integer; Var AtEdge: Boolean): Integer;
Var I,X1,X2: Integer; P: Integer;
Begin
 FindNoteX:=0;AtEdge:=False;
 P:=EdPart;
 If (P<1) Or (Parts[P].Ev=Nil) Then Exit;
 For I:=Parts[P].Cnt DownTo 1 Do
  If (Parts[P].Ev^[I].Kind=EK_NOTE) And (Parts[P].Ev^[I].D1=Pitch) Then Begin
   X1:=XT(Parts[P].Start+Parts[P].Ev^[I].T);
   X2:=EvX2(P,I);
   If (X>=X1-1) And (X<=X2+1) Then Begin
    FindNoteX:=I;
    AtEdge:=(X>=X2-2) And (X2-X1>6);
    Exit;
   End;
  End;
End;

Procedure SelOnlyEv(I: Integer);
Var K: Integer;
Begin
 For K:=1 To Parts[EdPart].Cnt Do Parts[EdPart].Ev^[K].Sel:=False;
 If I>0 Then Parts[EdPart].Ev^[I].Sel:=True;
End;

Procedure EdSnapshot;
Var K: Integer;
Begin
 For K:=1 To Parts[EdPart].Cnt Do Begin
  OrigEvT[K]:=Parts[EdPart].Ev^[K].T;
  OrigEvP[K]:=Parts[EdPart].Ev^[K].D1;
  OrigEvL[K]:=Parts[EdPart].Ev^[K].Len;
 End;
End;

Function EdQ: LongInt;
Begin
 If QuaTk[QuaI]>1 Then EdQ:=QuaTk[QuaI] Else EdQ:=1;
End;

Function DefLen: LongInt;
Begin
 If QuaTk[QuaI]>1 Then DefLen:=QuaTk[QuaI] Else DefLen:=PPQ Div 4;
End;

{ insere une note a l'instant absolu T ; retourne l'index }
Function InsertNoteAt(T: LongInt; Pitch: Integer): Integer;
Var P,I: Integer;
Begin
 InsertNoteAt:=0;
 P:=EdPart;
 If T<Parts[P].Start Then Exit;
 If (Pitch<0) Or (Pitch>127) Then Exit;
 If T>=Parts[P].Stop Then Parts[P].Stop:=(FloorDiv(T,BarTicks)+1)*BarTicks;
 I:=EvAdd(P,T-Parts[P].Start,DefLen,EK_NOTE,Pitch,DefVel);
 If I>0 Then Begin
  SelOnlyEv(0);
  Parts[P].Ev^[I].Sel:=True;
  Modified:=True;
 End;
 InsertNoteAt:=I;
End;

{ valeur d'une ligne de la bande de controleurs }
Function CtlYVal(Y: Integer): Integer;
Var V: LongInt;
Begin
 V:=((CS_B-1-Y)*127) Div (CS_B-CS_Y-4);
 CtlYVal:=Integer(Clamp(V,0,127));
End;

Procedure CtlEdit(X,Y: Integer; Erase: Boolean);
Var I,P,V,Dummy: Integer; T,Rel: LongInt; Found: Boolean; E: TEvt;
Begin
 P:=EdPart;
 V:=CtlYVal(Y);
 Found:=False;
 For I:=Parts[P].Cnt DownTo 1 Do Begin
  E:=Parts[P].Ev^[I];
  If CtlValue(E,Dummy) Then
   If Abs(XT(Parts[P].Start+E.T)-X)<=3 Then Begin
    Found:=True;
    If Erase Then Begin
     If CtlKind<>0 Then EvDel(P,I);
    End Else Begin
     Case CtlKind Of
      0: Parts[P].Ev^[I].D2:=Integer(Clamp(V,1,127));
      1: Parts[P].Ev^[I].D2:=V;
      6: Parts[P].Ev^[I].D1:=V;
     Else Parts[P].Ev^[I].D2:=V;
     End;
    End;
   End;
 End;
 If (Not Found) And (Not Erase) And (CtlKind<>0) Then Begin
  T:=Quant(TOfX(X),EdQ);
  If T<Parts[P].Start Then T:=Parts[P].Start;
  Rel:=T-Parts[P].Start;
  Case CtlKind Of
   1: EvAdd(P,Rel,0,EK_BEND,0,V);
   6: EvAdd(P,Rel,0,EK_CHANP,V,0);
  Else EvAdd(P,Rel,0,EK_CTRL,CtlNum[CtlKind],V);
  End;
 End;
 Modified:=True;
End;

Procedure EdNoteDialog(I: Integer);
Var P: Integer; S: String; N: Integer; V: LongInt; T: LongInt;
Begin
 P:=EdPart;
 S:=NoteName(Parts[P].Ev^[I].D1);
 If InputBox(T3('Pitch','Hauteur','Tonh'#148'he'),'C3 / 60',S,6) Then
  If ParseNote(S,N) Then Parts[P].Ev^[I].D1:=N;
 V:=Parts[P].Ev^[I].D2;
 If AskNum('Velocity','1-127',V,1,127) Then Parts[P].Ev^[I].D2:=V;
 V:=Parts[P].Ev^[I].Len;
 If AskNum(T3('Length','Dur'#130'e','L'#132'nge'),'ticks',V,1,30000) Then Parts[P].Ev^[I].Len:=V;
 S:=PosStr(Parts[P].Start+Parts[P].Ev^[I].T);
 While (S<>'') And (S[1]=' ') Do Delete(S,1,1);
 If InputBox('START','bar.beat.tick',S,14) Then
  If ParsePos(S,T) And (T>=Parts[P].Start) Then Begin
   Parts[P].Ev^[I].T:=T-Parts[P].Start;PartSort(P);
  End;
 Modified:=True;
End;

{ ---- Key Edit ---- }

Procedure KeyClick(X,Y: Integer; Btn: LongInt);
Var P,N,Pitch: Integer; Edge: Boolean; T: LongInt; NewV: LongInt; Right: Boolean;
Begin
 Right:=((Btn And 2)<>0) And ((Btn And 1)=0);
 P:=EdPart;
 If (Y>=HD_Y) And (Y<=HD_B) And (X>=KX0) And (X<=AR_X1) Then Begin
  SetPos(Max2(0,Quant(TOfX(X),EdQ)));DragKind:=40;Exit;
 End;
 { bande de controleurs }
 If (Y>=CS_Y-14) And (Y<=CS_Y-1) And (X>=48) And (X<=150) Then Begin
  CtlKind:=CycleIdx(CtlKind+1,1,8,Btn)-1;NeedDraw:=True;Exit;
 End;
 If (Y>=CS_Y) And (Y<=CS_B) And (X>=KX0) And (X<=AR_X1) Then Begin
  SaveUndo;
  CtlEdit(X,Y,(EdToolI=3) Or Right);
  DragKind:=25;DragX0:=X;NeedDraw:=True;Exit;
 End;
 If (X>=VS_X) And (Y>=KY0) And (Y<=KY1) Then Begin
  NewV:=ScrollClick(True,VS_X,KY0,SCR_W-1,KY1,X,Y,127-EdTop,128,KVIS);
  If NewV>=0 Then EdTop:=127-Integer(NewV) Else DragKind:=41;
  NeedDraw:=True;Exit;
 End;
 If (Y>=HS_Y) And (Y<=HS_B) And (X>=KX0) Then Begin
  NewV:=ScrollClick(False,KX0,HS_Y,SCR_W-1,HS_B,X,Y,EdT0 Div BeatTicks,2000,
        (AR_X1-KX0+1)*PPQ Div EdPx Div BeatTicks);
  If NewV>=0 Then EdT0:=NewV*BeatTicks Else DragKind:=42;
  NeedDraw:=True;Exit;
 End;
 If (X<KX0) And (Y>=KY0) And (Y<=KY1) Then Begin
  PreviewNote(PitchAtY(Y),DefVel);Exit;
 End;
 If (X<KX0) Or (X>AR_X1) Or (Y<KY0) Or (Y>KY1) Then Exit;
 Pitch:=PitchAtY(Y);
 T:=TOfX(X);
 N:=FindNoteX(X,Pitch,Edge);
 Case EdToolI Of
  1,2: Begin
        If N>0 Then Begin
         If DblClick(2000+N) Then Begin SaveUndo;EdNoteDialog(N);NeedDraw:=True;Exit;End;
         If Not Parts[P].Ev^[N].Sel Then SelOnlyEv(N);
         SaveUndo;
         EdSnapshot;
         DragP:=N;DragX0:=X;DragY0:=Y;DragT0:=T;DragMoved:=False;
         If Edge Then DragKind:=21 Else DragKind:=20;
         PreviewNote(Pitch,Parts[P].Ev^[N].D2);
        End Else If EdToolI=2 Then Begin
         SaveUndo;
         N:=InsertNoteAt(Quant(T-EdQ Div 2,EdQ),Pitch);
         If N>0 Then Begin
          EdSnapshot;
          DragP:=N;DragKind:=23;DragX0:=X;
          PreviewNote(Pitch,DefVel);
         End;
        End Else Begin
         SelOnlyEv(0);
         DragKind:=22;RbX1:=X;RbY1:=Y;RbX2:=X;RbY2:=Y;RbOn:=False;
        End;
       End;
  3: Begin
      SaveUndo;
      If N>0 Then Begin EvDel(P,N);Modified:=True;End;
      DragKind:=24;
     End;
  4: PreviewNote(Pitch,DefVel);
 End;
 NeedDraw:=True;
End;

Procedure KeyMove(X,Y: Integer);
Var P,I,N,Pitch,DP: Integer; D,T,Q: LongInt; Edge: Boolean; Mn,Mx: Integer;
Begin
 P:=EdPart;
 Case DragKind Of
  20: Begin
       Q:=EdQ;
       D:=Quant(TOfX(X)-TOfX(DragX0),Q);
       DP:=PitchAtY(Y)-PitchAtY(DragY0);
       If (D<>0) Or (DP<>0) Then DragMoved:=True;
       For I:=1 To Parts[P].Cnt Do
        If Parts[P].Ev^[I].Sel Then Begin
         T:=OrigEvT[I]+D;If T<0 Then T:=0;
         Parts[P].Ev^[I].T:=T;
         If Parts[P].Ev^[I].Kind=EK_NOTE Then
          Parts[P].Ev^[I].D1:=Integer(Clamp(OrigEvP[I]+DP,0,127));
        End;
       NeedDraw:=True;
      End;
  21,23: Begin
       Q:=EdQ;
       T:=Quant(TOfX(X),Q)-(Parts[P].Start+Parts[P].Ev^[DragP].T);
       If T<Q Then T:=Max2(1,Q);
       For I:=1 To Parts[P].Cnt Do
        If Parts[P].Ev^[I].Sel And (Parts[P].Ev^[I].Kind=EK_NOTE) Then Begin
         If I=DragP Then Parts[P].Ev^[I].Len:=T
         Else Parts[P].Ev^[I].Len:=Max2(1,OrigEvL[I]+(T-OrigEvL[DragP]));
        End;
       NeedDraw:=True;
      End;
  22: Begin
       If RbOn Then XorRect(RbX1,RbY1,RbX2,RbY2);
       RbX2:=X;RbY2:=Y;
       XorRect(RbX1,RbY1,RbX2,RbY2);RbOn:=True;
      End;
  24: Begin
       Pitch:=PitchAtY(Y);
       N:=FindNoteX(X,Pitch,Edge);
       If N>0 Then Begin EvDel(P,N);Modified:=True;NeedDraw:=True;End;
      End;
  25: Begin
       Mn:=X;Mx:=DragX0;
       If Mn>Mx Then Begin Mn:=DragX0;Mx:=X;End;
       If EdToolI=3 Then CtlEdit(X,Y,True)
       Else Begin
        While Mn<=Mx Do Begin
         CtlEdit(Mn,Y,False);
         Mn:=Mn+Integer(Max2(2,(EdQ*EdPx) Div PPQ));
        End;
       End;
       DragX0:=X;DragY0:=Y;
       NeedDraw:=True;
      End;
  40: Begin SetPos(Max2(0,Quant(TOfX(X),EdQ)));End;
  41: Begin
       EdTop:=127-Integer(ScrollDrag(True,VS_X,KY0,SCR_W-1,KY1,X,Y,128,KVIS));
       NeedDraw:=True;
      End;
  42: Begin
       EdT0:=ScrollDrag(False,KX0,HS_Y,SCR_W-1,HS_B,X,Y,2000,
         (AR_X1-KX0+1)*PPQ Div EdPx Div BeatTicks)*BeatTicks;
       NeedDraw:=True;
      End;
 End;
End;

Procedure KeyUp;
Var P,I,Mn,Mx,X1,X2,Y1,Y2,Yp: Integer;
Begin
 P:=EdPart;
 If P<1 Then Exit;
 If DragKind=22 Then Begin
  If RbOn Then XorRect(RbX1,RbY1,RbX2,RbY2);
  RbOn:=False;
  X1:=Integer(Min2(RbX1,RbX2));X2:=Integer(Max2(RbX1,RbX2));
  Y1:=Integer(Min2(RbY1,RbY2));Y2:=Integer(Max2(RbY1,RbY2));
  If View=V_KEY Then
   For I:=1 To Parts[P].Cnt Do
    If Parts[P].Ev^[I].Kind=EK_NOTE Then Begin
     Yp:=PY(Parts[P].Ev^[I].D1)+KEYH Div 2;
     Mn:=XT(Parts[P].Start+Parts[P].Ev^[I].T);Mx:=EvX2(P,I);
     If (Mx>=X1) And (Mn<=X2) And (Yp>=Y1) And (Yp<=Y2) Then
      Parts[P].Ev^[I].Sel:=True;
    End;
  NeedDraw:=True;
 End;
End;

{ ---- Score Edit ---- }

Function NoteAtScore(X,Y: Integer): Integer;
Var I: Integer;
Begin
 NoteAtScore:=0;
 For I:=1 To DNN Do
  If (Abs(DN[I].X-X)<=7) And (Abs(DN[I].Y-Y)<=4) Then NoteAtScore:=DN[I].Idx;
End;

Procedure ScoreClick(X,Y: Integer; Btn: LongInt);
Var P,N,Pitch,St,NewV: LongInt; T: LongInt;
Begin
 P:=EdPart;
 If (Y>=HD_Y) And (Y<=HD_B) And (X>=KX0) Then Begin
  SetPos(Max2(0,Quant(TOfX(X),EdQ)));DragKind:=40;Exit;
 End;
 If (Y>=HS_Y) And (Y<=HS_B) And (X>=KX0) Then Begin
  NewV:=ScrollClick(False,KX0,HS_Y,SCR_W-1,HS_B,X,Y,EdT0 Div BeatTicks,2000,
        (AR_X1-KX0+1)*PPQ Div EdPx Div BeatTicks);
  If NewV>=0 Then EdT0:=NewV*BeatTicks Else DragKind:=42;
  NeedDraw:=True;Exit;
 End;
 If (X<KX0) Or (Y<HD_B+2) Or (Y>HS_Y-2) Then Exit;
 N:=NoteAtScore(X,Y);
 St:=45-Round((Y-SC_Y0)/3);
 Pitch:=PitchOfStep(Integer(St));
 T:=Quant(TOfX(X),EdQ);
 Case EdToolI Of
  1: Begin
      If N>0 Then Begin
       If DblClick(3000+Integer(N)) Then Begin SaveUndo;EdNoteDialog(Integer(N));NeedDraw:=True;Exit;End;
       If Not Parts[P].Ev^[N].Sel Then SelOnlyEv(Integer(N));
       SaveUndo;EdSnapshot;
       DragP:=Integer(N);DragKind:=30;DragX0:=X;DragY0:=Y;
       PreviewNote(Parts[P].Ev^[N].D1,Parts[P].Ev^[N].D2);
      End Else SelOnlyEv(0);
     End;
  2: Begin
      SaveUndo;
      N:=InsertNoteAt(T,Integer(Pitch));
      If N>0 Then PreviewNote(Integer(Pitch),DefVel);
     End;
  3: If N>0 Then Begin SaveUndo;EvDel(P,Integer(N));Modified:=True;End;
  4: Begin
      If N>0 Then PreviewNote(Parts[P].Ev^[N].D1,Parts[P].Ev^[N].D2)
      Else PreviewNote(Integer(Pitch),DefVel);
     End;
 End;
 NeedDraw:=True;
End;

Procedure ScoreMove(X,Y: Integer);
Var P,I,DS,S0: Integer; Q,D,T: LongInt;
Begin
 P:=EdPart;
 If DragKind=30 Then Begin
  Q:=EdQ;
  D:=Quant(TOfX(X)-TOfX(DragX0),Q);
  S0:=Round((Y-DragY0)/3);
  For I:=1 To Parts[P].Cnt Do
   If Parts[P].Ev^[I].Sel Then Begin
    T:=OrigEvT[I]+D;If T<0 Then T:=0;
    Parts[P].Ev^[I].T:=T;
    DS:=StepOf(OrigEvP[I])-S0;
    Parts[P].Ev^[I].D1:=PitchOfStep(DS);
    If (OrigEvP[I] Mod 12 In [1,3,6,8,10]) And (S0=0) Then
     Parts[P].Ev^[I].D1:=OrigEvP[I];
   End;
  NeedDraw:=True;
 End Else If DragKind=40 Then SetPos(Max2(0,Quant(TOfX(X),EdQ)))
 Else If DragKind=42 Then Begin
  EdT0:=ScrollDrag(False,KX0,HS_Y,SCR_W-1,HS_B,X,Y,2000,
    (AR_X1-KX0+1)*PPQ Div EdPx Div BeatTicks)*BeatTicks;
  NeedDraw:=True;
 End;
End;

{ ---- Grid Edit ---- }

Procedure GridClick(X,Y: Integer; Btn: LongInt);
Var P,I,N: Integer; NewV,V: LongInt; S: String; T: LongInt; Nt: Integer;
Begin
 P:=EdPart;
 If (X>=VS_X) And (Y>=R0_Y) And (Y<=R0_Y+GVIS*GROWH-1) Then Begin
  NewV:=ScrollClick(True,VS_X,R0_Y,SCR_W-1,R0_Y+GVIS*GROWH-1,X,Y,ListTop-1,
        Max2(Parts[P].Cnt,GVIS),GVIS);
  If NewV>=0 Then ListTop:=Integer(NewV)+1 Else DragKind:=43;
  NeedDraw:=True;Exit;
 End;
 If (Y<R0_Y) Or (X>=VS_X) Then Exit;
 I:=ListTop+(Y-R0_Y) Div GROWH;
 If I>Parts[P].Cnt Then Begin
  If EdToolI=2 Then Begin
   SaveUndo;
   N:=InsertNoteAt(Parts[P].Start+Quant(Max2(0,CurPos-Parts[P].Start),EdQ),60);
   If N>0 Then ListSel:=N;
   NeedDraw:=True;
  End;
  Exit;
 End;
 ListSel:=I;SelOnlyEv(I);
 If EdToolI=3 Then Begin
  SaveUndo;EvDel(P,I);ListSel:=0;Modified:=True;NeedDraw:=True;Exit;
 End;
 If DblClick(4000+I) Then Begin
  SaveUndo;
  If X<115 Then Begin
   S:=PosStr(Parts[P].Start+Parts[P].Ev^[I].T);
   While (S<>'') And (S[1]=' ') Do Delete(S,1,1);
   If InputBox('START','bar.beat.tick',S,14) Then
    If ParsePos(S,T) And (T>=Parts[P].Start) Then Begin
     Parts[P].Ev^[I].T:=T-Parts[P].Start;PartSort(P);
    End;
  End Else If X<185 Then Begin
   V:=Parts[P].Ev^[I].Len;
   If AskNum(T3('Length','Dur'#130'e','L'#132'nge'),'ticks',V,0,30000) Then Parts[P].Ev^[I].Len:=V;
  End Else If X<285 Then Begin
  End Else If X<375 Then Begin
   If Parts[P].Ev^[I].Kind=EK_NOTE Then Begin
    S:=NoteName(Parts[P].Ev^[I].D1);
    If InputBox(T3('Pitch','Hauteur','Tonh'#148'he'),'C3 / 60',S,6) Then
     If ParseNote(S,Nt) Then Parts[P].Ev^[I].D1:=Nt;
   End Else Begin
    V:=Parts[P].Ev^[I].D1;
    If AskNum('DATA 1','0-127',V,0,127) Then Parts[P].Ev^[I].D1:=V;
   End;
  End Else Begin
   V:=Parts[P].Ev^[I].D2;
   If AskNum('DATA 2','0-127',V,0,127) Then Parts[P].Ev^[I].D2:=V;
  End;
  Modified:=True;
 End;
 NeedDraw:=True;
End;

{ ---- Drum Edit ---- }

Function DrumGrid: LongInt;
Begin
 If QuaTk[QuaI]>1 Then DrumGrid:=QuaTk[QuaI] Else DrumGrid:=PPQ Div 4;
End;

Function TOfDX(X: Integer): LongInt;
Begin
 TOfDX:=EdT0+((LongInt(X)-DX0)*PPQ) Div EdPx;
End;

Procedure DrumClick(X,Y: Integer; Btn: LongInt);
Var P,R,I,K: Integer; T,G: LongInt; Fnd: Boolean; NewV: LongInt; Right: Boolean;
Begin
 Right:=((Btn And 2)<>0) And ((Btn And 1)=0);
 P:=EdPart;
 If (Y>=P1_Y) And (Y<=P1_B) And (X>=426) And (X<=426+4*38) Then Begin
  K:=(X-426) Div 38+1;
  If K>4 Then K:=4;
  If Right Then Begin
   NewV:=DrumVel[K];
   If AskNum('DRUM VELOCITY','1-127',NewV,1,127) Then DrumVel[K]:=NewV;
  End Else DrumVelI:=K;
  NeedDraw:=True;Exit;
 End;
 If (Y>=HD_Y) And (Y<=HD_B) And (X>=DX0) Then Begin
  SetPos(Max2(0,Quant(TOfDX(X),DrumGrid)));DragKind:=44;Exit;
 End;
 If (Y>=HS_Y) And (Y<=HS_B) And (X>=DX0) Then Begin
  NewV:=ScrollClick(False,DX0,HS_Y,SCR_W-1,HS_B,X,Y,EdT0 Div BeatTicks,2000,
        (AR_X1-DX0+1)*PPQ Div EdPx Div BeatTicks);
  If NewV>=0 Then EdT0:=NewV*BeatTicks Else DragKind:=45;
  NeedDraw:=True;Exit;
 End;
 If (Y<KY0) Or (Y>=KY0+NDRUM*DROWH) Then Exit;
 R:=(Y-KY0) Div DROWH+1;
 If X<DX0 Then Begin PreviewNote(DrumNote[R],100);Exit;End;
 If X>AR_X1 Then Exit;
 G:=DrumGrid;
 T:=Quant(TOfDX(X)-G Div 2,G);
 If T<Parts[P].Start Then Exit;
 Fnd:=False;
 For I:=Parts[P].Cnt DownTo 1 Do
  If (Parts[P].Ev^[I].Kind=EK_NOTE) And (Parts[P].Ev^[I].D1=DrumNote[R]) And
     (Abs(Parts[P].Start+Parts[P].Ev^[I].T-T)<G Div 2+1) Then Begin
   If EdToolI<>4 Then Begin SaveUndo;EvDel(P,I);Modified:=True;End;
   Fnd:=True;
  End;
 If (Not Fnd) And (EdToolI<>3) Then Begin
  PreviewNote(DrumNote[R],DrumVel[DrumVelI]);
  If EdToolI<>4 Then Begin
   SaveUndo;
   If T>=Parts[P].Stop Then Parts[P].Stop:=(FloorDiv(T,BarTicks)+1)*BarTicks;
   EvAdd(P,T-Parts[P].Start,Max2(6,G Div 2),EK_NOTE,DrumNote[R],DrumVel[DrumVelI]);
   Modified:=True;
  End;
 End;
 NeedDraw:=True;
End;

{ ---- Master track ---- }

Procedure MstRange(Var TMin,TMax: Integer);
Var I: Integer;
Begin
 TMin:=TempoFix;TMax:=TempoFix;
 For I:=1 To NTemp Do Begin
  If Tempos[I].V<TMin Then TMin:=Tempos[I].V;
  If Tempos[I].V>TMax Then TMax:=Tempos[I].V;
 End;
 TMin:=(TMin Div 100)*100-100;TMax:=(TMax Div 100)*100+200;
 If TMin<0 Then TMin:=0;
End;

Procedure MasterClick(X,Y: Integer; Btn: LongInt);
Var I,TMin,TMax: Integer; NewV: LongInt; S: String; T: LongInt; R: Real; C: Integer;
Begin
 If (Y>=P1_Y) And (Y<=P1_B) Then Begin
  If (X>=60) And (X<=100) Then FlMaster:=Not FlMaster
  Else If (X>=164) And (X<=220) Then CmdTempo
  Else If (X>=272) And (X<=320) Then CmdSignature
  Else If (X>=334) And (X<=414) Then Begin
   SaveUndo;
   TempoSet(Quant(CurPos,BeatTicks),TempoAt(CurPos));FlMaster:=True;
  End Else If (X>=420) And (X<=500) Then Begin
   SaveUndo;TempoDel(MstSel);MstSel:=0;
  End Else If (X>=506) And (X<=576) Then Begin CmdSetView(V_ARR);Exit;End
  Else If (X>=580) And (X<=598) Then Begin If EdZoom>1 Then Dec(EdZoom);End
  Else If (X>=602) And (X<=620) Then Begin If EdZoom<6 Then Inc(EdZoom);End;
  NeedDraw:=True;Exit;
 End;
 If (Y>=HD_Y) And (Y<=HD_B) And (X>=48) Then Begin
  SetPos(Max2(0,Quant(EdT0+((LongInt(X)-48)*PPQ) Div EdPx,BeatTicks)));DragKind:=46;Exit;
 End;
 If (Y>=HS_Y) And (Y<=HS_B) And (X>=48) Then Begin
  NewV:=ScrollClick(False,48,HS_Y,SCR_W-1,HS_B,X,Y,EdT0 Div BeatTicks,2000,
        (AR_X1-48+1)*PPQ Div EdPx Div BeatTicks);
  If NewV>=0 Then EdT0:=NewV*BeatTicks Else DragKind:=47;
  NeedDraw:=True;Exit;
 End;
 If (X>=VS_X) And (Y>=ML_Y) Then Begin
  NewV:=ScrollClick(True,VS_X,ML_Y,SCR_W-1,ML_Y+MVIS*MROWH-1,X,Y,MstTop-1,
        Max2(NTemp,MVIS),MVIS);
  If NewV>=0 Then MstTop:=Integer(NewV)+1;
  NeedDraw:=True;Exit;
 End;
 If (Y>=MG_Y0) And (Y<=MG_Y1) And (X>=48) And (X<=AR_X1) Then Begin
  MstRange(TMin,TMax);
  T:=Quant(EdT0+((LongInt(X)-48)*PPQ) Div EdPx,BeatTicks);
  If T<0 Then T:=0;
  NewV:=TMin+(LongInt(MG_Y1-1-Y)*(TMax-TMin)) Div (MG_Y1-MG_Y0-2);
  SaveUndo;
  TempoSet(T,Integer(NewV));FlMaster:=True;
  NeedDraw:=True;Exit;
 End;
 If (Y>=ML_Y) And (Y<ML_Y+MVIS*MROWH) Then Begin
  I:=MstTop+(Y-ML_Y) Div MROWH;
  If I<=NTemp Then Begin
   MstSel:=I;
   If DblClick(5000+I) Then Begin
    S:=TempoStr(Tempos[I].V);
    If InputBox('TEMPO','BPM',S,8) Then Begin
     Val(S,R,C);
     If C=0 Then Tempos[I].V:=Integer(Clamp(Round(R*10),20,3000));
    End;
    If I>1 Then Begin
     S:=PosStr(Tempos[I].T);
     While (S<>'') And (S[1]=' ') Do Delete(S,1,1);
     If InputBox('START','bar.beat.tick',S,14) Then
      If ParsePos(S,T) And (T>0) Then Tempos[I].T:=T;
    End;
   End;
  End;
  NeedDraw:=True;
 End;
End;

{ ====================================================================== }
{                       EVENEMENTS PRINCIPAUX                            }
{ ====================================================================== }

Procedure MouseDown(X,Y: Integer; Btn: LongInt);
Var T: Integer;
Begin
 T:=TitleHit(X,Y);
 If T>0 Then Begin RunMenu(T,True);Exit;End;
 If (Y>=TB_Y) And (Y<TB_Y+TB_H) Then Begin
  If X<TB_H Then Begin
   If View=V_ARR Then CmdQuit
   Else CmdSetView(V_ARR);
  End;
  Exit;
 End;
 If Y>=TR_Y-2 Then Begin TransportClick(X,Y,Btn);Exit;End;
 If View<>V_ARR Then Begin
  { barre de parametres des editeurs }
  If (Y>=P1_Y) And (Y<=P1_B) And (View<>V_MASTER) Then Begin
   If (X>=4) And (X<=60) Then Begin EditClose(True);Exit;End;
   If (X>=66) And (X<=142) Then Begin EditClose(False);Exit;End;
   If (X>=200) And (X<=248) Then QuaI:=CycleIdx(QuaI,0,NQUA,Btn)
   Else If (X>=306) And (X<=388) Then EdToolI:=ToolCycle(EdToolI,4,Btn)
   Else If (X>=580) And (X<=598) Then Begin If EdZoom>1 Then Dec(EdZoom);End
   Else If (X>=602) And (X<=620) Then Begin If EdZoom<6 Then Inc(EdZoom);End;
   If View=V_KEY Then
    If (X>=426) And (X<=476) Then Begin
     Info('Length follows QUANTIZE.','La longueur suit QUANTIZE.','L'#132'nge folgt QUANTIZE.');
    End;
   NeedDraw:=True;
   Exit;
  End;
 End;
 Case View Of
  V_ARR: ArrangeClick(X,Y,Btn);
  V_KEY: KeyClick(X,Y,Btn);
  V_SCORE: ScoreClick(X,Y,Btn);
  V_GRID: GridClick(X,Y,Btn);
  V_DRUM: DrumClick(X,Y,Btn);
  V_MASTER: MasterClick(X,Y,Btn);
 End;
End;

Procedure MouseMove(X,Y: Integer);
Begin
 If DragKind=0 Then Exit;
 If (MB And 3)=0 Then Exit;
 Case View Of
  V_ARR: ArrangeMove(X,Y);
  V_KEY: KeyMove(X,Y);
  V_SCORE: ScoreMove(X,Y);
  V_DRUM: Begin
           If DragKind=44 Then SetPos(Max2(0,Quant(TOfDX(X),DrumGrid)))
           Else If DragKind=45 Then Begin
            EdT0:=ScrollDrag(False,DX0,HS_Y,SCR_W-1,HS_B,X,Y,2000,
              (AR_X1-DX0+1)*PPQ Div EdPx Div BeatTicks)*BeatTicks;
            NeedDraw:=True;
           End;
          End;
  V_GRID: If DragKind=43 Then Begin
           ListTop:=Integer(ScrollDrag(True,VS_X,R0_Y,SCR_W-1,R0_Y+GVIS*GROWH-1,X,Y,
             Max2(Parts[EdPart].Cnt,GVIS),GVIS))+1;
           NeedDraw:=True;
          End;
  V_MASTER: If DragKind=46 Then SetPos(Max2(0,Quant(EdT0+((LongInt(X)-48)*PPQ) Div EdPx,BeatTicks)))
            Else If DragKind=47 Then Begin
             EdT0:=ScrollDrag(False,48,HS_Y,SCR_W-1,HS_B,X,Y,2000,
               (AR_X1-48+1)*PPQ Div EdPx Div BeatTicks)*BeatTicks;
             NeedDraw:=True;
            End;
 End;
End;

Procedure MouseUp;
Begin
 If (View=V_KEY) Or (View=V_SCORE) Then KeyUp;
 If (View=V_ARR) And (DragKind>=1) And (DragKind<=3) And DragMoved Then Modified:=True;
 If (View=V_ARR) And (DragKind=3) And (DragP>0) Then
  If Not Parts[DragP].Used Then DragP:=0;
 DragKind:=0;
 NeedDraw:=True;
End;

{ ---- clavier ---- }

Procedure ScrollBars(K: Word);
Begin
 Case View Of
  V_ARR: Case K Of
          K_LEFT: Begin If ViewBar>0 Then Dec(ViewBar);NeedDraw:=True;End;
          K_RIGHT: Begin If ViewBar<990 Then Inc(ViewBar);NeedDraw:=True;End;
          K_UP: Begin If CurTrk>1 Then Dec(CurTrk);
                 If CurTrk<ArrTop Then ArrTop:=CurTrk;NeedDraw:=True;End;
          K_DOWN: Begin If CurTrk<NTRK Then Inc(CurTrk);
                   If CurTrk>=ArrTop+VISR Then ArrTop:=CurTrk-VISR+1;NeedDraw:=True;End;
          K_PGUP: Begin ArrTop:=Integer(Max2(1,ArrTop-VISR+1));NeedDraw:=True;End;
          K_PGDN: Begin ArrTop:=Integer(Min2(NTRK-VISR+1,ArrTop+VISR-1));NeedDraw:=True;End;
         End;
  V_KEY,V_SCORE,V_DRUM,V_MASTER:
         Case K Of
          K_LEFT: Begin EdT0:=Max2(0,EdT0-BeatTicks);NeedDraw:=True;End;
          K_RIGHT: Begin EdT0:=EdT0+BeatTicks;NeedDraw:=True;End;
          K_UP: Begin If EdTop<127 Then Inc(EdTop);NeedDraw:=True;End;
          K_DOWN: Begin If EdTop>KVIS Then Dec(EdTop);NeedDraw:=True;End;
          K_PGUP: Begin EdT0:=Max2(0,EdT0-BarTicks);NeedDraw:=True;End;
          K_PGDN: Begin EdT0:=EdT0+BarTicks;NeedDraw:=True;End;
         End;
  V_GRID: Case K Of
           K_UP: Begin If ListSel>1 Then Dec(ListSel);
                  If ListSel<ListTop Then ListTop:=ListSel;
                  If ListSel>=1 Then SelOnlyEv(ListSel);NeedDraw:=True;End;
           K_DOWN: Begin If ListSel<Parts[EdPart].Cnt Then Inc(ListSel);
                    If ListSel>=ListTop+GVIS Then ListTop:=ListSel-GVIS+1;
                    SelOnlyEv(ListSel);NeedDraw:=True;End;
           K_PGUP: Begin ListTop:=Integer(Max2(1,ListTop-GVIS));NeedDraw:=True;End;
           K_PGDN: Begin ListTop:=Integer(Max2(1,Min2(ListTop+GVIS,
                     Max2(1,Parts[EdPart].Cnt-GVIS+1))));NeedDraw:=True;End;
          End;
 End;
End;

Procedure HandleKey(K: Word);
Var P: Integer;
Begin
 Case K Of
  K_ESC: Begin
          If Playing Then StopPlay
          Else If View<>V_ARR Then CmdSetView(V_ARR);
         End;
  K_F1: CmdSetView(V_ARR);
  K_F1+1..K_F1+5: CmdSetView(K-K_F1+1);
  K_F1+6: DlgPlayParam;
  K_F1+7: CmdMidiProc;
  K_F1+8: TempoNudge(-10);
  K_F1+9: TempoNudge(10);
  K_F11: CmdHelp;
  K_F12: RunMenu(2,False);
  32: CmdStart;
  42: CmdRecord;
  Ord('['): LocFromPos(True);
  Ord(']'): LocFromPos(False);
  Ord('-'): Begin If Oct>0 Then Dec(Oct);End;
  Ord('+'),Ord('='): Begin If Oct<8 Then Inc(Oct);End;
  K_HOME: Begin SetPos(0);ViewBar:=0;If View<>V_ARR Then EdT0:=0;NeedDraw:=True;End;
  K_END: Begin SetPos(SongEnd);NeedDraw:=True;End;
  K_LEFT,K_RIGHT,K_UP,K_DOWN,K_PGUP,K_PGDN: ScrollBars(K);
  K_DEL: Begin
          If View=V_ARR Then CmdDeleteParts Else DeleteSelEvents;
         End;
  K_ENTER: Begin
            If View=V_ARR Then CmdEditPart
            Else If View=V_GRID Then Begin
             If ListSel>=1 Then Begin SaveUndo;EdNoteDialog(ListSel);NeedDraw:=True;End;
            End Else CmdSetView(V_ARR);
           End;
  K_INS: If View=V_GRID Then Begin
          SaveUndo;
          ListSel:=InsertNoteAt(Parts[EdPart].Start+Quant(Max2(0,CurPos-Parts[EdPart].Start),EdQ),60);
          NeedDraw:=True;
         End;
  K_TAB: Begin If View=V_ARR Then Begin CurTrk:=(CurTrk Mod NTRK)+1;
          If CurTrk>=ArrTop+VISR Then ArrTop:=CurTrk-VISR+1;
          If CurTrk<ArrTop Then ArrTop:=CurTrk;NeedDraw:=True;End;End;
  14: CmdNew;
  15: CmdOpen;
  19: CmdSave;
  17: CmdQuit;
  7: CmdGoto;
  26: DoUndo;
  24: If View=V_ARR Then CmdCopyParts(True) Else CmdCopyEv(True);
  3: If View=V_ARR Then CmdCopyParts(False) Else CmdCopyEv(False);
  22: If View=V_ARR Then CmdPaste Else CmdPasteEv;
  1: CmdSelAll(True);
 Else
  Begin
   P:=PianoKey(K);
   If P>=0 Then Begin
    LiveNote(P,DefVel,False);
    If (Not Playing) And (View<>V_ARR) And (EdPart>0) And Parts[EdPart].Used And
       (EdToolI=2) And (View=V_KEY) Then Begin End;
   End;
  End;
 End;
End;


{ ====================================================================== }
{                          INITIALISATION                                }
{ ====================================================================== }

Procedure InitData;
Var S: String;
Begin
 S:=Upper(Copy(GetEnv('LANGUAGE'),1,2));
 If S='EN' Then Lang:=0
 Else If (S='GR') Or (S='DE') Then Lang:=2
 Else Lang:=1;
 FillChar(Parts,SizeOf(Parts),0);
 FillChar(Snd,SizeOf(Snd),0);
 FillChar(Pend,SizeOf(Pend),0);
 FlCycle:=False;FlPunch:=False;FlClick:=False;FlMaster:=False;FlOverdub:=True;
 FlSolo:=False;FlEdSolo:=False;FlChase:=True;FlFollow:=True;FlReset:=False;
 FlTempoRec:=False;FlThru:=True;
 SyncMode:=0;SyncDel:=0;CountIn:=0;AutoQ:=0;ClickMode:=0;
 ClkHi:=76;ClkLo:=77;ClkVel:=100;ClkChan:=10;
 HumVel:=0;HumLen:=0;MidiInChan:=0;RemOn:=0;RemStart:=24;RemStop:=26;
 OutDev:=0;MpuPort:=$330;DefVel:=100;Oct:=4;PrnDest:='CUBASE.PRN';
 MpOn:=False;MpRep:=3;MpEcho:=24;MpQuant:=0;MpEDec:=0;MpVDec:=-12;MpNDec:=0;
 MpChan:=0;MpOut:=0;
 View:=V_ARR;ZoomI:=3;SnapI:=1;QuaI:=3;ToolI:=1;CycMode:=0;EdToolI:=2;
 EdZoom:=3;CtlKind:=0;EdPart:=0;EdBakEv:=Nil;EdBakCnt:=0;EdT0:=0;EdTop:=84;
 ListTop:=1;ListSel:=0;MstSel:=0;MstTop:=1;
 DrumVel[1]:=40;DrumVel[2]:=70;DrumVel[3]:=100;DrumVel[4]:=127;DrumVelI:=3;
 UndoValid:=False;ClipN:=0;EvClipN:=0;
 Playing:=False;Recording:=False;CountInOn:=False;SoloAny:=False;
 SpkFreq:=0;ClickUntil:=0;InSt:=0;InN:=0;PlayX:=-1;PlayShown:=-1;
 MenuOpen:=0;MenuHi:=0;DragKind:=0;LastClkId:=-1;NeedDraw:=True;
 MX:=0;MY:=0;MB:=0;LastB:=0;
 MBuf:=Nil;Msg:=Nil;
 {$IFDEF FPC}
 CurSaved:=False;CurShown:=False;
 {$ENDIF}
 EvUsed:=0;
 InitSong;
 Randomize;
End;

Procedure ShowHelpLine;
Var H: Text;
Begin
 Assign(H,'');Rewrite(H);
 If Lang=0 Then Begin
  WriteLn(H,'CUBASE - Graphical clone of the Steinberg Cubase MIDI sequencer.');
  WriteLn(H);
  WriteLn(H,'Usage : CUBASE [file.ARR | file.MID] [/PLAY] [/?]');
  WriteLn(H);
  WriteLn(H,'  file.ARR  Arrangement to open.');
  WriteLn(H,'  file.MID  Standard MIDI file to import.');
  WriteLn(H,'  /PLAY     Play the file immediately in the GUI.');
  WriteLn(H,'  /?        Show this help.');
  WriteLn(H,'  In the GUI, the space bar plays / stops the song.');
  WriteLn(H);
  WriteLn(H,'Language : French by default, LANGUAGE=EN for English,');
  WriteLn(H,'LANGUAGE=GR for German.');
 End Else If Lang=2 Then Begin
  WriteLn(H,'CUBASE - Grafischer Klon des Steinberg Cubase MIDI-Sequenzers.');
  WriteLn(H);
  WriteLn(H,'Aufruf : CUBASE [Datei.ARR | Datei.MID] [/PLAY] [/?]');
  WriteLn(H);
  WriteLn(H,'  /PLAY  Datei sofort in der Oberfl'#132'che abspielen.');
  WriteLn(H,'  Leertaste = Song abspielen / stoppen.');
  WriteLn(H);
  WriteLn(H,'Sprache : Franz'#148'sisch als Standard, LANGUAGE=EN f'#129'r Englisch,');
  WriteLn(H,'LANGUAGE=GR f'#129'r Deutsch.');
 End Else Begin
  WriteLn(H,'CUBASE - Cette commande permet de lancer le clone graphique '+
            'du s'#130'quenceur MIDI Cubase de Steinberg.');
  WriteLn(H);
  WriteLn(H,'Syntaxe : CUBASE [fichier.ARR | fichier.MID] [/PLAY] [/?]');
  WriteLn(H);
  WriteLn(H,'  fichier.ARR  Arrangement '#133' ouvrir.');
  WriteLn(H,'  fichier.MID  Fichier MIDI standard '#133' importer.');
  WriteLn(H,'  /PLAY        Joue imm'#130'diatement le fichier dans l''interface.');
  WriteLn(H,'  /?           Affiche cette aide.');
  WriteLn(H,'  Dans l''interface, la barre d''espacement joue / arr'#136'te le morceau.');
  WriteLn(H);
  WriteLn(H,'Langue : fran'#135'ais par d'#130'faut, LANGUAGE=EN pour l''anglais,');
  WriteLn(H,'LANGUAGE=GR pour l''allemand.');
 End;
 Close(H);
End;

{ retourne True si un fichier a ete charge }
Function LoadCommandLine: Boolean;
Var Name,Ext: String; I: Integer; PlayNow,Loaded: Boolean;
Begin
 Name:='';PlayNow:=False;Loaded:=False;
 For I:=1 To ParamCount Do
  If (Upper(ParamStr(I))='/PLAY') Or (Upper(ParamStr(I))='-PLAY') Or
     (Upper(ParamStr(I))='--PLAY') Then PlayNow:=True
  Else If Name='' Then Name:=ParamStr(I);
 LoadCommandLine:=False;
 If Name='' Then Exit;
 Ext:=Upper(Copy(Name,Length(Name)-3,4));
 If Ext='.MID' Then Begin
  If LoadMidi(Name) Then Begin
   ResetView;
   SongName:=Copy(ShortName(Name),1,Pos('.',ShortName(Name)+'.')-1)+'.ARR';
   SongNamed:=False;
   Loaded:=True;
  End;
 End Else Begin
  Name:=AddExt(Name,'ARR');
  If FileExists(Name) Then
   If LoadArr(Name,False) Then Begin ResetView;Loaded:=True;End;
 End;
 If PlayNow And Loaded Then CmdStart;
 LoadCommandLine:=Loaded;
End;

Procedure MainLoop;
Var E: TEvent;
Begin
 Repeat
  If NeedDraw Then DrawAll;
  PollEvent(E);
  Case E.Kind Of
   1: HandleKey(E.Key);
   2: MouseDown(E.X,E.Y,E.B);
   3: MouseUp;
   4: MouseMove(E.X,E.Y);
  End;
  UpdatePlayDisplay;
 Until Quit;
End;

Var
 UF : File;

BEGIN
 Quit:=False;
 If (ParamCount>=1) And ((ParamStr(1)='/?') Or (ParamStr(1)='-h')
     Or (ParamStr(1)='--help')) Then Begin
  Lang:=1;
  If Upper(Copy(GetEnv('LANGUAGE'),1,2))='EN' Then Lang:=0;
  If (Upper(Copy(GetEnv('LANGUAGE'),1,2))='GR') Or
     (Upper(Copy(GetEnv('LANGUAGE'),1,2))='DE') Then Lang:=2;
  ShowHelpLine;
  Halt(0);
 End;
 InitData;
 LoadOptions(GetEnv('LANGUAGE')='');
 {$IFDEF FPC}
 If OutDev=1 Then OutDev:=0;
 {$ENDIF}
 InitializeGraphics;
 If MouseDriverFound Then ShowMouse;
 {$IFDEF MSWINDOWS}
 If OutDev=0 Then
  If Not SynthStart Then OutDev:=2;
 {$ENDIF}
 {$IFNDEF FPC}
 If OutDev=1 Then MpuInit;
 {$ENDIF}
 If Not LoadCommandLine Then Begin
  DrawAll;
  CmdAbout;
 End;
 MainLoop;
 AllNotesOff;
 {$IFDEF MSWINDOWS}
 SynthStop;
 {$ENDIF}
 HideMouse;
 CloseGraph;
 {$I-}
 Assign(UF,UNDOFILE);
 Erase(UF);
 {$I+}
 If IOResult<>0 Then ;
END.
