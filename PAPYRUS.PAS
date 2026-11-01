{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/office-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal
  @description: Clone de l'application 3Papyrus
}

Program PAPYRUS;

{$IFNDEF FPC}
 {$M 16384,0,655360}
{$ENDIF}

Uses {$IFDEF FPC}
      DOS,Crt,PtcGraph,PtcCrt,PtcMouse
     {$ELSE}
      DOS,Crt,Graph
     {$ENDIF};

{ ====================================================================== }
{                              CONSTANTES                                }
{ ====================================================================== }

Const
 VERSION_TEXT = '1.00';
 SCR_W        = 640;
 SCR_H        = 480;
 MENU_H       = 18;
 INK          = 0;
 PAPER        = 15;
 NMENU        = 9;
 FKEY_Y       = 420;
 TBH          = 20;      { hauteur de la barre de titre }
 SBW          = 18;      { largeur des barres de defilement }
 PALW         = 28;      { largeur de la palette d'outils }
 GAPPX        = 6;       { espace entre deux pages }

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
 K_CLEFT  = 371;
 K_CRIGHT = 372;
 K_CHOME  = 375;
 K_CEND   = 373;
 K_STAB   = 271;

 { Attributs de caracteres }
 A_BOLD  = 1;
 A_ITAL  = 2;
 A_UND   = 4;
 A_OUT   = 8;
 A_LIGHT = 16;
 A_SUP   = 32;
 A_SUB   = 64;

 { Histoires (flux de texte) : 0 principal, 1 en-tete, 2 pied, 3.. cadres }
 NSTORY  = 27;
 MAXOBJ  = 60;
 MAINCAP = 24000;
 MAINPAR = 600;
 FRCAP   = 2000;
 FRPAR   = 60;
 HFCAP   = 500;
 HFPAR   = 8;
 MAXLN   = 2200;
 TMPLN   = 300;
 MAXPG   = 99;
 MAXFMT  = 8;

 { Objets }
 OB_TEXT  = 1;
 OB_RECT  = 2;
 OB_LINE  = 3;
 OB_IMAGE = 4;

 { Outils }
 TL_SEL   = 1;
 TL_TEXT  = 2;
 TL_FRAME = 3;
 TL_RECT  = 4;
 TL_DARK  = 5;
 TL_GREY  = 6;

 SizeTab : Array[0..7] Of Byte = (6,8,10,12,14,18,24,36);
 FamName : Array[0..1] Of String[5] = ('Times','Swiss');

{ ====================================================================== }
{                                TYPES                                   }
{ ====================================================================== }

Type
 TBytes = Array[0..32000] Of Byte;
 PBytes = ^TBytes;
 TTab = Packed Record P: Integer; K: Byte; End;
 TPara = Packed Record
  Al,Spc,Fm,NT: Byte;          { alignement, interligne*10, format, nb tabs }
  LI,FI,SA: Integer;           { retraits et espace apres (dmm) }
  Tb: Array[1..6] Of TTab;
 End;
 TParaArr = Array[0..800] Of TPara;
 PParaArr = ^TParaArr;

 TStory = Record
  Len,Cap,NP,MaxP: Integer;
  T,A,F: PBytes;
  Pa: PParaArr;
  Used: Boolean;
 End;

 TLine = Record
  S,E,N: Integer;            { debut, fin, debut suivant }
  X,Y,H,Asc: Integer;        { dmm }
  Ex,Ns: Integer;            { justification }
  Reg,Pa: Integer;
  Fl: Byte;                  { 1 trait d'union, 2 fin de paragraphe, 4 LF, 8 saut }
 End;
 TLineArr = Array[0..MAXLN] Of TLine;
 PLineArr = ^TLineArr;

 TObj = Record
  Kind,Fill,Bord,Ang,Col: Byte;
  Pg: Integer;
  X,Y,W,H: Integer;           { dmm relatif a la page }
  St: Integer;
  Img: PBytes;
  IW,IH: Integer;
 End;

 TFmt = Record
  Name: String[18];
  Fam,Sz,At,Al,Spc: Byte;
 End;

 TEvent = Record
  { 0 rien, 1 touche, 2 bouton bas, 3 bouton haut, 4 mouvement }
  Kind : Byte;
  Key  : Word;
  X,Y,B: LongInt;
 End;

 TCtl = Record
  Kind,Id,Grp: Byte;
  X,Y,W,H: Integer;
  Txt: String[44];
  Str: String[40];
  Val: Integer;
  Sfx: String[3];
  Num,On: Boolean;
 End;

{ ====================================================================== }
{                              VARIABLES                                 }
{ ====================================================================== }

Var
 { Document }
 St        : Array[0..NSTORY-1] Of TStory;
 Obj       : Array[1..MAXOBJ] Of TObj;
 NObj      : Integer;
 Fmts      : Array[1..MAXFMT] Of TFmt;
 NFmt      : Integer;
 PgFmt     : Integer;
 PgW,PgH   : Integer;            { dmm }
 MarL,MarR,MarT,MarB : Integer;  { mm }
 Mirror    : Boolean;
 HeadH,FootH,NCols,ColGap : Integer;
 PgStart,HFFrom : Integer;
 FnA,FnB,FnC,FnD,FnE : Integer;
 HyphOn    : Boolean;
 HyphLang  : Integer;
 DocName   : String[79];
 Named,Modified : Boolean;

 { Mises en page calculees }
 ML        : PLineArr;           { lignes du texte principal }
 NML       : Integer;
 TLn       : PLineArr;           { lignes temporaires (cadres, en-tete) }
 NTL       : Integer;
 NPages    : Integer;
 LayoutOK  : Boolean;

 { Edition }
 ASt       : Integer;            { histoire active }
 Cur,SelA  : Integer;            { curseur, ancre de selection (-1 aucune) }
 CurPg     : Integer;            { page courante pour en-tete/pied }
 TypA,TypF : Byte;               { attributs de frappe }
 MarkMode  : Boolean;
 LastTyping: Boolean;
 CurLine   : Integer;
 WantX     : LongInt;

 { Presse-papiers et annulation }
 ClipT,ClipA,ClipF : PBytes;
 ClipN     : Integer;
 UndoOK    : Boolean;
 UndoSt    : Integer;
 UndoCur   : Integer;
 UndoT,UndoA,UndoF : PBytes;
 UndoLen   : Integer;
 UndoPa    : PParaArr;
 UndoNP    : Integer;

 { Affichage }
 Zoom      : Integer;
 ScrX,ScrY : LongInt;
 ToolsOn,RulerOn,FormatOn,GuidesOn,Preview,FullWin : Boolean;
 Tool      : Integer;
 SelObj    : Integer;
 WX1,WY1,WX2,WY2 : Integer;     { fenetre }
 VX1,VY1,VX2,VY2 : Integer;     { zone du document }
 TabKind   : Integer;           { type de tabulation du prochain clic }
 AutoHyph  : Boolean;

 { Touches de fonction }
 FKFont    : Array[1..10] Of Byte;   { 0 aucun, sinon famille*8+indice taille+1 }
 FKStyle   : Array[1..10] Of Byte;

 { Souris / evenements }
 MX,MY,MB,LastB : LongInt;
 PrevMX,PrevMY  : LongInt;
 Quit,NeedDraw  : Boolean;
 MenuOpen,MenuHi : Integer;
 Dragging  : Integer;
 DragX,DragY,DragOX,DragOY : LongInt;
 LastClickT: LongInt;
 CaretOn   : Boolean;
 CaretX,CaretY1,CaretY2 : Integer;
 CaretT    : LongInt;

 { Police bitmap }
 G8        : Array[0..255,0..7] Of Byte;
 GL        : Array[0..255,0..15] Of Word;
 InkL,InkR : Array[0..255] Of ShortInt;
 A16       : Array[0..255] Of Byte;
 BM        : Array[0..82,0..70] Of Byte;

 { Contexte de dessin du texte }
 CX1,CY1,CX2,CY2 : LongInt;     { fenetre de clipping (ecran) }
 RgOX,RgOY : LongInt;           { origine de la region en pixels ecran }
 RgAng     : Integer;
 FrX,FrY,FrW,FrH : LongInt;     { cadre en pixels (pour la rotation) }
 LastFill  : Integer;
 LXs       : Array[0..400] Of LongInt;
 Rep       : String;

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
 Function MouseDriverFound: Boolean;
 Begin
  MouseDriverFound := True;
 End;

 Procedure ShowMouse;
 Begin
  { Pas d'implementation pour Free Pascal }
 End;

 Procedure HideMouse;
 Begin
  { Pas d'implementation pour Free Pascal }
 End;
{$ENDIF}

{ ====================================================================== }
{                       UTILITAIRES GENERAUX                             }
{ ====================================================================== }

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

Function TrimStr(S: String): String;
Begin
 While (Length(S)>0) And (S[1]=' ') Do Delete(S,1,1);
 While (Length(S)>0) And (S[Length(S)]=' ') Do Delete(S,Length(S),1);
 TrimStr:=S;
End;

Function Min2(A,B: LongInt): LongInt;
Begin
 If A<B Then Min2:=A Else Min2:=B;
End;

Function Max2(A,B: LongInt): LongInt;
Begin
 If A>B Then Max2:=A Else Max2:=B;
End;

Function ValInt(Const S: String; Def: LongInt): LongInt;
Var V: LongInt; Code: Integer; T: String;
Begin
 T:=TrimStr(S);
 Val(T,V,Code);
 If (Code<>0) Or (T='') Then ValInt:=Def Else ValInt:=V;
End;

Function FileExists(Const N: String): Boolean;
Var F: File;
Begin
 {$I-}
 Assign(F,N);
 Reset(F,1);
 {$I+}
 If IOResult=0 Then Begin
  Close(F);
  FileExists:=True;
 End Else FileExists:=False;
End;

Function ShortName(Const N: String): String;
Var I: Integer; S: String;
Begin
 S:=N;
 I:=Length(S);
 While (I>0) And (S[I]<>'\') And (S[I]<>'/') And (S[I]<>':') Do Dec(I);
 ShortName:=Copy(S,I+1,255);
End;

Function AddExt(Const N,Ext: String): String;
Var I: Integer; Dot: Boolean;
Begin
 Dot:=False;
 For I:=1 To Length(N) Do If N[I]='.' Then Dot:=True;
 If Dot Or (N='') Then AddExt:=N Else AddExt:=N+'.'+Ext;
End;

Function Tick: LongInt;
Var H,M,S,S100: Word;
Begin
 GetTime(H,M,S,S100);
 Tick:=((LongInt(H)*60+M)*60+S)*100+S100;
End;

Function IsLetter(C: Byte): Boolean;
Begin
 IsLetter:=((C>=65) And (C<=90)) Or ((C>=97) And (C<=122)) Or (C>=128);
End;

{ ====================================================================== }
{                  GEOMETRIE ET CONVERSIONS (dmm <-> pixels)             }
{ ====================================================================== }

{ 1 dmm = 0,1 mm ; a 100 % : 2,68 pixels par mm }
Function D2P(D: LongInt): LongInt;
Begin
 If D>=0 Then D2P:=(D*268*Zoom+50000) Div 100000
 Else D2P:=-((-D*268*Zoom+50000) Div 100000);
End;

Function P2D(P: LongInt): LongInt;
Begin
 P2D:=(P*100000) Div (268*Zoom);
End;

Function PageWPx: LongInt;
Begin
 PageWPx:=D2P(PgW);
End;

Function PageHPx: LongInt;
Begin
 PageHPx:=D2P(PgH);
End;

Function StridePx: LongInt;
Begin
 StridePx:=PageHPx+GAPPX;
End;

{ Position ecran du coin haut-gauche de la page P }
Function PageX0: LongInt;
Begin
 PageX0:=VX1+6-ScrX;
End;

Function PageY0(P: Integer): LongInt;
Begin
 PageY0:=VY1+4-ScrY+LongInt(P-1)*StridePx;
End;

Function BodyX(P: Integer): Integer;
Begin
 If Mirror And Not Odd(P) Then BodyX:=MarR*10 Else BodyX:=MarL*10;
End;

Function TextWd: Integer;
Begin
 TextWd:=PgW-(MarL+MarR)*10;
End;

Function ColWd: Integer;
Var W: Integer;
Begin
 W:=(TextWd-(NCols-1)*ColGap*10) Div NCols;
 If W<100 Then W:=100;
 ColWd:=W;
End;

Function BodyYd: Integer;
Begin
 BodyYd:=(MarT+HeadH)*10;
End;

Function BodyHd: Integer;
Var H: Integer;
Begin
 H:=PgH-(MarT+MarB+HeadH+FootH)*10;
 If H<150 Then H:=150;
 BodyHd:=H;
End;

{ ====================================================================== }
{                    POLICE BITMAP (extraite du BGI)                     }
{ ====================================================================== }

Function GBit(C,X,Y: Integer): Integer;
Begin
 If (X<0) Or (X>7) Or (Y<0) Or (Y>7) Then GBit:=0
 Else If (G8[C,Y] And ($80 Shr X))<>0 Then GBit:=1 Else GBit:=0;
End;

{ Lit la police 8x8 du BGI puis la double avec l'algorithme EPX }
Procedure BuildFont;
Var C,X,Y,I,J,L,R: Integer; P,A,B,Cc,D: Integer; V: Word; Q: Array[0..3] Of Integer;
Begin
 SetFillStyle(SolidFill,PAPER);
 Bar(0,0,15,15);
 For C:=0 To 255 Do Begin
  SetFillStyle(SolidFill,PAPER);
  Bar(0,0,7,7);
  If C>=32 Then Begin
   SetColor(INK);
   OutTextXY(0,0,Chr(C));
  End;
  For Y:=0 To 7 Do Begin
   G8[C,Y]:=0;
   For X:=0 To 7 Do
    If GetPixel(X,Y)=INK Then G8[C,Y]:=G8[C,Y] Or ($80 Shr X);
  End;
 End;
 For C:=0 To 255 Do Begin
  L:=99;R:=-1;
  For Y:=0 To 7 Do
   For X:=0 To 7 Do
    If GBit(C,X,Y)=1 Then Begin
     If X<L Then L:=X;
     If X>R Then R:=X;
    End;
  If R<0 Then Begin InkL[C]:=0;InkR[C]:=-1;A16[C]:=7;End
  Else Begin InkL[C]:=L;InkR[C]:=R;A16[C]:=(R-L+1)*2+2;End;
  For Y:=0 To 7 Do Begin
   GL[C,Y*2]:=0;GL[C,Y*2+1]:=0;
   For X:=0 To 7 Do Begin
    P:=GBit(C,X,Y);A:=GBit(C,X,Y-1);B:=GBit(C,X+1,Y);
    Cc:=GBit(C,X-1,Y);D:=GBit(C,X,Y+1);
    Q[0]:=P;Q[1]:=P;Q[2]:=P;Q[3]:=P;
    If (Cc=A) And (Cc<>D) And (A<>B) Then Q[0]:=A;
    If (A=B) And (A<>Cc) And (B<>D) Then Q[1]:=B;
    If (D=Cc) And (D<>B) And (Cc<>A) Then Q[2]:=Cc;
    If (B=D) And (B<>A) And (D<>Cc) Then Q[3]:=D;
    V:=$8000 Shr (X*2);
    If Q[0]=1 Then GL[C,Y*2]:=GL[C,Y*2] Or V;
    If Q[1]=1 Then GL[C,Y*2]:=GL[C,Y*2] Or (V Shr 1);
    If Q[2]=1 Then GL[C,Y*2+1]:=GL[C,Y*2+1] Or V;
    If Q[3]=1 Then GL[C,Y*2+1]:=GL[C,Y*2+1] Or (V Shr 1);
   End;
  End;
 End;
End;

{ Hauteur de cellule (dmm) pour un octet de police/attribut }
Function CellD(Fn,At: Byte): Integer;
Var P: Integer;
Begin
 P:=SizeTab[Fn And 7];
 If (At And (A_SUP Or A_SUB))<>0 Then P:=P*65 Div 100;
 CellD:=P*39 Div 10;
End;

{ Largeur d'un caractere (dmm) }
Function ChW(Ch,Fn,At: Byte): Integer;
Var C: LongInt; W: LongInt;
Begin
 C:=CellD(Fn,At);
 W:=(LongInt(A16[Ch])+((Fn Shr 3) And 1))*C*5 Div 128;
 If (At And A_BOLD)<>0 Then W:=W+C Div 14+1;
 If W<1 Then W:=1;
 ChW:=W;
End;

{ ====================================================================== }
{                      HISTOIRES (flux de texte)                         }
{ ====================================================================== }

Const
 DEFF    = 18;          { Times 10 pt, couleur noire }
 CLIPCAP = 8000;

Var
 HM        : Array[0..80] Of Boolean;
 XA        : Array[0..400] Of LongInt;

Procedure DefPara(Var P: TPara);
Begin
 FillChar(P,SizeOf(P),0);
 P.Spc:=14;
End;

Procedure AllocStory(I,ACap,AMax: Integer);
Begin
 With St[I] Do Begin
  Cap:=ACap;MaxP:=AMax;
  GetMem(T,ACap);GetMem(A,ACap);GetMem(F,ACap);
  GetMem(Pa,AMax*SizeOf(TPara));
  Len:=0;NP:=1;Used:=True;
  DefPara(Pa^[0]);
 End;
End;

Procedure ClearStory(I: Integer);
Begin
 With St[I] Do Begin
  Len:=0;NP:=1;
  DefPara(Pa^[0]);
 End;
End;

Procedure FreeStory(I: Integer);
Begin
 With St[I] Do Begin
  If Not Used Then Exit;
  FreeMem(T,Cap);FreeMem(A,Cap);FreeMem(F,Cap);
  FreeMem(Pa,MaxP*SizeOf(TPara));
  Used:=False;Len:=0;NP:=0;
 End;
End;

Function ParaOf(S,Ps: Integer): Integer;
Var I,N: Integer;
Begin
 N:=0;
 With St[S] Do
  For I:=0 To Ps-1 Do If T^[I]=13 Then Inc(N);
 ParaOf:=N;
End;

Function ParaStart(S,Pn: Integer): Integer;
Var I,N: Integer;
Begin
 ParaStart:=0;
 If Pn<=0 Then Exit;
 N:=0;
 With St[S] Do Begin
  For I:=0 To Len-1 Do
   If T^[I]=13 Then Begin
    Inc(N);
    If N=Pn Then Begin ParaStart:=I+1;Exit;End;
   End;
  ParaStart:=Len;
 End;
End;

Function ParaEndOf(S,Ps: Integer): Integer;
Var I: Integer;
Begin
 With St[S] Do Begin
  I:=Ps;
  While (I<Len) And (T^[I]<>13) Do Inc(I);
  ParaEndOf:=I;
 End;
End;

Function ParaBegOf(S,Ps: Integer): Integer;
Begin
 With St[S] Do Begin
  While (Ps>0) And (T^[Ps-1]<>13) Do Dec(Ps);
  ParaBegOf:=Ps;
 End;
End;

Function StIns(S,Ps: Integer; Ch,At,Fn: Byte): Boolean;
Var Pn: Integer;
Begin
 StIns:=False;
 With St[S] Do Begin
  If (Len>=Cap) Or ((Ch=13) And (NP>=MaxP)) Then Exit;
  If Ps<Len Then Begin
   Move(T^[Ps],T^[Ps+1],Len-Ps);
   Move(A^[Ps],A^[Ps+1],Len-Ps);
   Move(F^[Ps],F^[Ps+1],Len-Ps);
  End;
  T^[Ps]:=Ch;A^[Ps]:=At;F^[Ps]:=Fn;
  Inc(Len);
  If Ch=13 Then Begin
   Pn:=ParaOf(S,Ps);
   Move(Pa^[Pn],Pa^[Pn+1],(NP-Pn)*SizeOf(TPara));
   Inc(NP);
  End;
 End;
 StIns:=True;
End;

Procedure StDel(S,P1,P2: Integer);
Var I,K,Pn: Integer;
Begin
 With St[S] Do Begin
  If P1<0 Then P1:=0;
  If P2>Len Then P2:=Len;
  If P2<=P1 Then Exit;
  K:=0;
  For I:=P1 To P2-1 Do If T^[I]=13 Then Inc(K);
  If K>0 Then Begin
   Pn:=ParaOf(S,P1);
   Move(Pa^[Pn+K+1],Pa^[Pn+1],(NP-Pn-K-1)*SizeOf(TPara));
   Dec(NP,K);
  End;
  If P2<Len Then Begin
   Move(T^[P2],T^[P1],Len-P2);
   Move(A^[P2],A^[P1],Len-P2);
   Move(F^[P2],F^[P1],Len-P2);
  End;
  Len:=Len-(P2-P1);
 End;
End;

Procedure StAppend(S: Integer; Const Tx: String; At,Fn: Byte);
Var I: Integer;
Begin
 For I:=1 To Length(Tx) Do StIns(S,St[S].Len,Ord(Tx[I]),At,Fn);
End;

Function HeapOK(Sz: LongInt): Boolean;
Begin
 {$IFDEF FPC}
 HeapOK:=True;
 {$ELSE}
 HeapOK:=MaxAvail>=Sz;
 {$ENDIF}
End;

{ ---- annulation (1 niveau) ---- }
Procedure PushUndo;
Begin
 If UndoT=Nil Then Begin
  If Not HeapOK(LongInt(MAINCAP)*3+20000) Then Exit;
  GetMem(UndoT,MAINCAP);GetMem(UndoA,MAINCAP);GetMem(UndoF,MAINCAP);
  GetMem(UndoPa,MAINPAR*SizeOf(TPara));
 End;
 UndoSt:=ASt;
 UndoLen:=St[ASt].Len;
 UndoCur:=Cur;
 Move(St[ASt].T^,UndoT^,UndoLen);
 Move(St[ASt].A^,UndoA^,UndoLen);
 Move(St[ASt].F^,UndoF^,UndoLen);
 Move(St[ASt].Pa^,UndoPa^,St[ASt].NP*SizeOf(TPara));
 UndoNP:=St[ASt].NP;
 UndoOK:=True;
End;

{ ====================================================================== }
{                        COUPURE DES MOTS (cesure)                       }
{ ====================================================================== }

Function LoCase(C: Byte): Byte;
Begin
 If (C>=65) And (C<=90) Then LoCase:=C+32
 Else If C=144 Then LoCase:=130
 Else If C=142 Then LoCase:=132
 Else If C=153 Then LoCase:=148
 Else If C=154 Then LoCase:=129
 Else LoCase:=C;
End;

Function Vow(C: Byte): Boolean;
Begin
 C:=LoCase(C);
 Vow:=(C In [97,101,105,111,117,121]) Or
  (C In [129,130,131,132,133,134,136,137,138,139,140,141]) Or
  (C In [147,148,149,150,151,152,160,161,162,163]);
End;

Function Pair(A,B: Byte): Boolean;
{ groupes de consonnes inseparables }
Var S: String[2];
Begin
 S:=Chr(LoCase(A))+Chr(LoCase(B));
 Pair:=(S='bl') Or (S='br') Or (S='cl') Or (S='cr') Or (S='dr') Or (S='fl') Or
   (S='fr') Or (S='gl') Or (S='gr') Or (S='pl') Or (S='pr') Or (S='tr') Or
   (S='ch') Or (S='ph') Or (S='th') Or (S='sh') Or (S='gn') Or (S='qu') Or
   (S='vr') Or (S='ck') Or (S='pf');
 If (HyphLang=1) And (S='st') Then Pair:=False;
End;

{ Calcule les points de coupure : HM[K] = coupure possible apres K lettres }
Procedure HyphMarks(Const W: String);
Var N,I,J,Lead,Trail: Integer;
Begin
 N:=Length(W);
 For I:=0 To 80 Do HM[I]:=False;
 Lead:=2;Trail:=3;
 If HyphLang=6 Then Trail:=2;
 If N<Lead+Trail Then Exit;
 For I:=Lead To N-Trail Do Begin
  { coupure entre W[I] et W[I+1] }
  If Vow(Ord(W[I])) And (I+2<=N) And Not Vow(Ord(W[I+1])) And Vow(Ord(W[I+2])) Then
   HM[I]:=True
  Else If (Not Vow(Ord(W[I]))) And (Not Vow(Ord(W[I+1]))) And (I>=2) And
          Vow(Ord(W[I-1])) Then Begin
   { voyelle consonne | consonne : coupe sauf groupe inseparable }
   If Not Pair(Ord(W[I]),Ord(W[I+1])) Then HM[I]:=True;
  End Else If Vow(Ord(W[I])) And (I+2<=N) And Not Vow(Ord(W[I+1])) And
          Not Vow(Ord(W[I+2])) And Pair(Ord(W[I+1]),Ord(W[I+2])) Then HM[I]:=True;
  { pas de coupure juste avant une apostrophe, ni entre deux voyelles }
  If (W[I]='''') Or (W[I+1]='''') Then HM[I]:=False;
 End;
 For J:=1 To N Do If Not IsLetter(Ord(W[J])) Then HM[J]:=False;
End;

{ ====================================================================== }
{                        MISE EN PAGE DU TEXTE                           }
{ ====================================================================== }

Function Wd(S,I: Integer): Integer;
Var C: Byte;
Begin
 With St[S] Do Begin
  C:=T^[I];
  If C=1 Then Wd:=ChW(48,F^[I],A^[I])*2
  Else If (C=10) Or (C=13) Or (C=12) Then Wd:=0
  Else Wd:=ChW(C,F^[I],A^[I]);
 End;
End;

Function NextStop(Const Pr: TPara; X: LongInt; Var K: Byte): LongInt;
Var I: Integer; B: LongInt;
Begin
 B:=-1;K:=0;
 For I:=1 To Pr.NT Do
  If (Pr.Tb[I].P>X) And ((B<0) Or (Pr.Tb[I].P<B)) Then Begin
   B:=Pr.Tb[I].P;K:=Pr.Tb[I].K;
  End;
 If B<0 Then Begin B:=((X Div 127)+1)*127;K:=0;End;
 NextStop:=B;
End;

{ Largeur de la tabulation situee en position Ps ; X = abscisse absolue }
Function TabAdv(S: Integer; Const Pr: TPara; Ps: Integer; X: LongInt; Lim: Integer): LongInt;
Var Stop,Edge,W: LongInt; K: Byte; J: Integer;
Begin
 Stop:=NextStop(Pr,X,K);
 If K=0 Then Begin TabAdv:=Stop-X;Exit;End;
 W:=0;J:=Ps+1;
 With St[S] Do
  While (J<Lim) And (J<Len) And (T^[J]<>9) And (T^[J]<>10) Do Begin
   If (K=3) And ((T^[J]=46) Or (T^[J]=44)) Then Break;
   W:=W+Wd(S,J);
   Inc(J);
  End;
 If K=1 Then Edge:=Stop-W Div 2 Else Edge:=Stop-W;
 If Edge<X Then Edge:=X;
 TabAdv:=Edge-X;
End;

Procedure LayoutPara(S,P0,PE,Pn: Integer; W: LongInt; L: PLineArr; Var N: Integer;
  Mx: Integer);
Var
 LS,I,Brk,Nx,En,J,WS,WE,Bp,Hp,K,Al: Integer;
 Avail,X,Wc,Ind,Sh,HW,LW: LongInt;
 Pr: TPara;
 First,HasTab: Boolean;
 Ch,Fl: Byte;
 MaxCell,Cd,Ns,Ex: Integer;
 Wrd: String;
Begin
 Pr:=St[S].Pa^[Pn];
 LS:=P0;First:=True;
 With St[S] Do
 Repeat
  If N>=Mx Then Exit;
  Ind:=Pr.LI;
  If First Then Ind:=Ind+Pr.FI;
  If Ind<0 Then Ind:=0;
  Avail:=W-Ind;
  If Avail<60 Then Avail:=60;
  En:=-1;Nx:=-1;Fl:=0;HasTab:=False;Brk:=-1;HW:=0;
  I:=LS;X:=0;XA[0]:=0;
  While I<PE Do Begin
   Ch:=T^[I];
   If Ch=10 Then Begin En:=I;Nx:=I+1;Fl:=4;Break;End;
   If Ch=12 Then Begin En:=I;Nx:=I+1;Fl:=12;Break;End;
   If Ch=9 Then Begin HasTab:=True;Wc:=TabAdv(S,Pr,I,Ind+X,PE);End
   Else Wc:=Wd(S,I);
   If (((X+Wc>Avail) And (Ch<>32)) Or (I-LS>=390)) And (I>LS) Then Begin
    Hp:=-1;
    If HyphOn And IsLetter(Ch) Then Begin
     J:=I;
     While (J>LS) And IsLetter(T^[J-1]) Do Dec(J);
     WS:=J;
     J:=I;
     While (J<PE) And IsLetter(T^[J]) Do Inc(J);
     WE:=J;
     If (WE-WS>=5) And (WE-WS<=40) Then Begin
      Wrd:='';
      For K:=WS To WE-1 Do Wrd:=Wrd+Chr(T^[K]);
      HyphMarks(Wrd);
      For K:=WE-WS-2 Downto 2 Do
       If HM[K] Then Begin
        Bp:=WS+K;
        If (Bp>LS) And (Bp<=I) Then Begin
         HW:=ChW(45,F^[Bp-1],A^[Bp-1]);
         If XA[Bp-LS]+HW<=Avail Then Begin Hp:=Bp;Break;End;
        End;
       End;
     End;
    End;
    If Hp>0 Then Begin En:=Hp;Nx:=Hp;Fl:=1;End
    Else If Brk>LS Then Begin En:=Brk;Nx:=Brk;End
    Else Begin En:=I;Nx:=I;End;
    Break;
   End;
   X:=X+Wc;
   Inc(I);
   XA[I-LS]:=X;
   If Ch=32 Then Brk:=I;
  End;
  If En<0 Then Begin En:=PE;Nx:=PE+1;Fl:=2;End;
  If (Fl And 1)=0 Then Begin
   While (En>LS) And (T^[En-1]=32) Do Dec(En);
  End;
  { largeur du contenu }
  LW:=XA[En-LS];
  If (En-LS>=0) And (En-LS<=400) Then Else LW:=0;
  If Fl=1 Then LW:=LW+HW Else HW:=0;
  Al:=Pr.Al;
  If HasTab Then Al:=0;
  Sh:=0;Ex:=0;Ns:=0;
  If (Al=1) And ((Fl And 7)=0) Then Begin
   For K:=LS To En-1 Do If T^[K]=32 Then Inc(Ns);
   If (Ns>0) And (Avail>LW) Then Ex:=Avail-LW Else Ns:=0;
  End Else If Al=2 Then Begin Sh:=(Avail-LW) Div 2;If Sh<0 Then Sh:=0;End
  Else If Al=3 Then Begin Sh:=Avail-LW;If Sh<0 Then Sh:=0;End;
  MaxCell:=0;
  For K:=LS To En-1 Do Begin
   Cd:=CellD(F^[K],A^[K]);
   If Cd>MaxCell Then MaxCell:=Cd;
  End;
  If MaxCell=0 Then Begin
   If PE<Len Then MaxCell:=CellD(F^[PE],A^[PE])
   Else If LS>0 Then MaxCell:=CellD(F^[LS-1],A^[LS-1])
   Else MaxCell:=CellD(TypF,TypA);
  End;
  L^[N].S:=LS;L^[N].E:=En;L^[N].N:=Nx;
  L^[N].X:=Ind+Sh;
  L^[N].H:=MaxCell*Pr.Spc Div 10;
  L^[N].Asc:=L^[N].H-MaxCell Div 4;
  L^[N].Ex:=Ex;L^[N].Ns:=Ns;L^[N].Reg:=0;L^[N].Pa:=Pn;L^[N].Fl:=Fl;L^[N].Y:=0;
  Inc(N);
  If Nx>PE Then Exit;
  LS:=Nx;First:=False;
 Until False;
End;

{ Histoire d'un cadre : objet associe }
Function ObjOfStory(S: Integer): Integer;
Var I: Integer;
Begin
 ObjOfStory:=0;
 For I:=1 To NObj Do If (Obj[I].Kind=OB_TEXT) And (Obj[I].St=S) Then ObjOfStory:=I;
End;

Function StoryWidth(S: Integer): LongInt;
Var O: Integer;
Begin
 If S<=2 Then Begin StoryWidth:=TextWd;Exit;End;
 O:=ObjOfStory(S);
 If O=0 Then Begin StoryWidth:=500;Exit;End;
 If Odd(Obj[O].Ang) Then StoryWidth:=Obj[O].H-40 Else StoryWidth:=Obj[O].W-40;
End;

{ Mise en page d'une histoire dans une seule boite (en-tete, pied, cadre) }
Procedure LayoutBox(S: Integer);
Var Pn,P0,PE,I,Y: Integer; W: LongInt;
Begin
 W:=StoryWidth(S);
 NTL:=0;P0:=0;
 For Pn:=0 To St[S].NP-1 Do Begin
  PE:=ParaEndOf(S,P0);
  LayoutPara(S,P0,PE,Pn,W,TLn,NTL,TMPLN-1);
  P0:=PE+1;
 End;
 Y:=0;
 For I:=0 To NTL-1 Do Begin
  TLn^[I].Y:=Y;TLn^[I].Reg:=0;
  Y:=Y+TLn^[I].H;
  If (TLn^[I].Fl And 2)<>0 Then Y:=Y+St[S].Pa^[TLn^[I].Pa].SA;
 End;
End;

Procedure LayoutMain;
Var Pn,P0,PE,I,Reg,Y,Mp: Integer;
Begin
 NML:=0;P0:=0;
 For Pn:=0 To St[0].NP-1 Do Begin
  PE:=ParaEndOf(0,P0);
  LayoutPara(0,P0,PE,Pn,ColWd,ML,NML,MAXLN-1);
  P0:=PE+1;
 End;
 Reg:=0;Y:=0;
 For I:=0 To NML-1 Do Begin
  If (Y+ML^[I].H>BodyHd) And (Y>0) Then Begin Inc(Reg);Y:=0;End;
  ML^[I].Reg:=Reg;ML^[I].Y:=Y;
  Y:=Y+ML^[I].H;
  If (ML^[I].Fl And 2)<>0 Then Y:=Y+St[0].Pa^[ML^[I].Pa].SA;
  If (ML^[I].Fl And 8)<>0 Then Begin Reg:=((Reg Div NCols)+1)*NCols;Y:=0;End;
 End;
 NPages:=Reg Div NCols+1;
 Mp:=1;
 For I:=1 To NObj Do If Obj[I].Pg>Mp Then Mp:=Obj[I].Pg;
 If Mp>NPages Then NPages:=Mp;
 If NPages>MAXPG Then NPages:=MAXPG;
 LayoutOK:=True;
End;

Procedure EnsureLayout;
Begin
 If Not LayoutOK Then LayoutMain;
End;

{ Lignes de l'histoire S (le texte principal est deja mis en page) }
Procedure GetLines(S: Integer; Var L: PLineArr; Var N: Integer);
Begin
 EnsureLayout;
 If S=0 Then Begin L:=ML;N:=NML;End
 Else Begin LayoutBox(S);L:=TLn;N:=NTL;End;
End;

Function LineOfPos(L: PLineArr; N,Ps: Integer): Integer;
Var I: Integer;
Begin
 LineOfPos:=N-1;
 For I:=0 To N-1 Do
  If (Ps>=L^[I].S) And (Ps<L^[I].N) Then Begin LineOfPos:=I;Exit;End;
End;

{ Abscisses (dmm, relatives a la region) de chaque frontiere de caractere }
Procedure LineXs(S: Integer; L: PLineArr; I: Integer);
Var Pr: TPara; X: LongInt; K,Nn,Ls,Pe,J: Integer; Wc: LongInt;
Begin
 Ls:=L^[I].S;Nn:=L^[I].N;
 If Nn-Ls>398 Then Nn:=Ls+398;
 Pr:=St[S].Pa^[L^[I].Pa];
 Pe:=ParaEndOf(S,Ls);
 X:=L^[I].X;J:=0;
 LXs[0]:=X;
 For K:=Ls To Nn-1 Do Begin
  If K>=St[S].Len Then Wc:=0
  Else If St[S].T^[K]=9 Then Wc:=TabAdv(S,Pr,K,X,Pe)
  Else Wc:=Wd(S,K);
  If (K<St[S].Len) And (St[S].T^[K]=32) And (K<L^[I].E) And (L^[I].Ns>0) Then Begin
   Wc:=Wc+L^[I].Ex Div L^[I].Ns;
   If J<L^[I].Ex Mod L^[I].Ns Then Inc(Wc);
   Inc(J);
  End;
  X:=X+Wc;
  LXs[K-Ls+1]:=X;
 End;
End;

Function PosAtX(S: Integer; L: PLineArr; I: Integer; Xd: LongInt): Integer;
Var K,Ls,Ee: Integer;
Begin
 LineXs(S,L,I);
 Ls:=L^[I].S;Ee:=L^[I].E;
 PosAtX:=Ee;
 For K:=0 To Ee-Ls-1 Do
  If Xd<(LXs[K]+LXs[K+1]) Div 2 Then Begin PosAtX:=Ls+K;Exit;End;
End;

Function XOfPos(S: Integer; L: PLineArr; I,Ps: Integer): LongInt;
Begin
 LineXs(S,L,I);
 If Ps<L^[I].S Then Ps:=L^[I].S;
 If Ps-L^[I].S>398 Then Ps:=L^[I].S+398;
 XOfPos:=LXs[Ps-L^[I].S];
End;

Procedure Relayout;
Begin
 LayoutOK:=False;
End;

{ ====================================================================== }
{                       PRIMITIVES GRAPHIQUES                            }
{ ====================================================================== }

Const
 PatChecker : FillPatternType = ($AA,$55,$AA,$55,$AA,$55,$AA,$55);
 PatStripe  : FillPatternType = ($FF,$00,$FF,$00,$FF,$00,$FF,$00);
 PatTrack   : FillPatternType = ($88,$22,$88,$22,$88,$22,$88,$22);
 PatDark    : FillPatternType = ($77,$DD,$77,$DD,$77,$DD,$77,$DD);
 PatLight   : FillPatternType = ($80,$00,$08,$00,$80,$00,$08,$00);
 PatHatch   : FillPatternType = ($88,$44,$22,$11,$88,$44,$22,$11);
 ColMap     : Array[0..8] Of Byte = (15,0,5,3,1,14,12,2,6);
 ColName    : Array[0..8] Of String[8] = ('blanc','noir','magenta','cyan','violet',
   'jaune','orange','vert','brun');

Procedure SetFill(C: Integer);
Begin
 If LastFill<>C Then Begin SetFillStyle(SolidFill,C);LastFill:=C;End;
End;

Procedure Box(X1,Y1,X2,Y2,C: Integer);
Begin
 SetFill(C);
 Bar(X1,Y1,X2,Y2);
End;

Procedure Frame(X1,Y1,X2,Y2: Integer);
Begin
 SetColor(INK);
 SetLineStyle(SolidLn,0,1);
 Rectangle(X1,Y1,X2,Y2);
End;

Procedure SetPat(Const Pat: FillPatternType);
Var Q: FillPatternType; I: Integer;
Begin
 For I:=1 To 8 Do Q[I]:=Not Pat[I];
 SetFillPattern(Q,PAPER);
 LastFill:=-1;
End;

Procedure PatBar(X1,Y1,X2,Y2: Integer; Const Pat: FillPatternType);
Begin
 SetPat(Pat);
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

Function TextW(Const S: String): Integer;
Var I,N: Integer;
Begin
 N:=0;
 For I:=1 To Length(S) Do If S[I]<>'&' Then Inc(N);
 TextW:=N*8;
End;

{ Texte avec lettre soulignee : '&' precede la lettre }
Procedure UText(X,Y: Integer; Const S: String; Col: Integer);
Var I,P: Integer; Mark: Boolean;
Begin
 SetColor(Col);
 P:=0;Mark:=False;
 For I:=1 To Length(S) Do Begin
  If (S[I]='&') And Not Mark Then Mark:=True
  Else Begin
   OutTextXY(X+P*8,Y,S[I]);
   If Mark Then Begin
    SetLineStyle(SolidLn,0,1);
    Line(X+P*8,Y+9,X+P*8+7,Y+9);
    Mark:=False;
   End;
   Inc(P);
  End;
 End;
End;

Procedure GreyText(X,Y: Integer; Const S: String);
Var I,J,W: Integer;
Begin
 PText(X,Y,S);
 W:=TextW(S);
 For J:=0 To 7 Do
  For I:=0 To W-1 Do
   If Odd(I+J) Then
    If GetPixel(X+I,Y+J)=INK Then PutPixel(X+I,Y+J,PAPER);
End;

Procedure SmallText(X,Y: Integer; Const S: String; Col: Integer);
Var I: Integer;
Begin
 SetColor(Col);
 For I:=1 To Length(S) Do OutTextXY(X+(I-1)*6,Y,S[I]);
End;

Function InBox(X,Y,X1,Y1,X2,Y2: LongInt): Boolean;
Begin
 InBox:=(X>=X1) And (X<=X2) And (Y>=Y1) And (Y<=Y2);
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
 SetFillStyle(SolidFill,INK);LastFill:=-1;
 SetColor(INK);
 FillPoly(3,Pt);
End;

{ Bouton GEM : OK (Def) a double bordure }
Procedure Button(X1,Y1,X2,Y2: Integer; Const S: String; Def,Enabled: Boolean);
Var TX: Integer;
Begin
 Box(X1,Y1,X2,Y2,PAPER);
 Frame(X1,Y1,X2,Y2);
 If Def Then Begin Frame(X1+1,Y1+1,X2-1,Y2-1);Frame(X1-1,Y1-1,X2+1,Y2+1);End;
 TX:=(X1+X2+1-TextW(S)) Div 2;
 If Enabled Then UText(TX,(Y1+Y2-6) Div 2,S,INK)
 Else Begin
  GreyText(TX,(Y1+Y2-6) Div 2,S);
 End;
End;

{ ====================================================================== }
{                  EVENEMENTS (clavier / souris)                         }
{ ====================================================================== }

Function ShiftDown: Boolean;
Begin
 {$IFDEF FPC}
 ShiftDown:=False;
 {$ELSE}
 ShiftDown:=(Mem[$40:$17] And 3)<>0;
 {$ENDIF}
End;

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
 If ((MB And 1)<>0) And ((LastB And 1)=0) Then E.Kind:=2
 Else If ((MB And 1)=0) And ((LastB And 1)<>0) Then E.Kind:=3
 Else If (MX<>PrevMX) Or (MY<>PrevMY) Then E.Kind:=4
 Else Delay(4);
End;

{ ====================================================================== }
{                      TEXTE : GLYPHES ET LIGNES                         }
{ ====================================================================== }

Var
 DrawPage : Integer;
 NoSel    : Boolean;

Procedure CBar(X1,Y1,X2,Y2: LongInt; C: Integer);
Begin
 If X1<CX1 Then X1:=CX1;
 If Y1<CY1 Then Y1:=CY1;
 If X2>CX2 Then X2:=CX2;
 If Y2>CY2 Then Y2:=CY2;
 If (X1>X2) Or (Y1>Y2) Then Exit;
 SetFill(C);
 Bar(X1,Y1,X2,Y2);
End;

{ rectangle local (region) -> ecran, selon l'angle du cadre }
Procedure MapR(RX1,RY1,RX2,RY2: LongInt; Var SX1,SY1,SX2,SY2: LongInt);
Begin
 Case RgAng Of
  1: Begin SX1:=FrX+RY1;SX2:=FrX+RY2;SY1:=FrY+FrH-1-RX2;SY2:=FrY+FrH-1-RX1;End;
  2: Begin SX1:=FrX+FrW-1-RX2;SX2:=FrX+FrW-1-RX1;SY1:=FrY+FrH-1-RY2;
          SY2:=FrY+FrH-1-RY1;End;
  3: Begin SX1:=FrX+FrW-1-RY2;SX2:=FrX+FrW-1-RY1;SY1:=FrY+RX1;SY2:=FrY+RX2;End;
 Else Begin SX1:=FrX+RX1;SX2:=FrX+RX2;SY1:=FrY+RY1;SY2:=FrY+RY2;End;
 End;
End;

Procedure LRect(RX1,RY1,RX2,RY2: LongInt; C: Integer);
Var A,B,D,E: LongInt;
Begin
 MapR(RX1,RY1,RX2,RY2,A,B,D,E);
 CBar(A,B,D,E,C);
End;

Function OnPx(Ty,Tx,Tw,H: Integer; At: Byte): Boolean;
Var V: Boolean;
Begin
 OnPx:=False;
 If (Tx<0) Or (Tx>=Tw) Or (Ty<0) Or (Ty>=H) Then Exit;
 OnPx:=BM[Ty,Tx]<>0;
End;

{ Dessine un caractere dans la boite (X,Y) de hauteur H (pixels region) }
Procedure DrawGlyph(Ch: Byte; X,Y: LongInt; H: Integer; At,Col: Byte);
Var Tw,Ty,Tx,Gx0,Gx1,Gy0,Gy1,Gx,Gy,Cnt,Ar,Sh,Run,Gw: Integer; On: Boolean;
 Bold,Out_: Boolean;
Begin
 If H<2 Then H:=2;
 If H>80 Then H:=80;
 If InkR[Ch]<InkL[Ch] Then Exit;
 Gw:=(InkR[Ch]-InkL[Ch]+1)*2;
 Tw:=Gw*H*5 Div 128;
 If Tw<1 Then Tw:=1;
 If Tw>66 Then Tw:=66;
 Bold:=(At And A_BOLD)<>0;
 Out_:=(At And A_OUT)<>0;
 For Ty:=0 To H-1 Do Begin
  Gy0:=Ty*16 Div H;
  Gy1:=((Ty+1)*16-1) Div H;
  If Gy1<Gy0 Then Gy1:=Gy0;
  If Gy1>15 Then Gy1:=15;
  For Tx:=0 To Tw-1 Do Begin
   Gx0:=(LongInt(Tx)*2560 Div H) Div 100+InkL[Ch]*2;
   Gx1:=((LongInt(Tx)+1)*2560 Div H-1) Div 100+InkL[Ch]*2;
   If Gx1<Gx0 Then Gx1:=Gx0;
   If Gx1>15 Then Gx1:=15;
   Cnt:=0;Ar:=0;
   For Gy:=Gy0 To Gy1 Do
    For Gx:=Gx0 To Gx1 Do Begin
     Inc(Ar);
     If (GL[Ch,Gy] And ($8000 Shr Gx))<>0 Then Inc(Cnt);
    End;
   If Cnt*100>=Ar*34 Then BM[Ty,Tx]:=1 Else BM[Ty,Tx]:=0;
  End;
  BM[Ty,Tw]:=0;
 End;
 If Bold Then Begin
  For Ty:=0 To H-1 Do
   For Tx:=Tw Downto 1 Do
    If BM[Ty,Tx-1]<>0 Then BM[Ty,Tx]:=BM[Ty,Tx] Or 1;
  Inc(Tw);
 End;
 If Out_ Then Begin
  { garde les pixels de bord seulement }
  For Ty:=0 To H-1 Do
   For Tx:=0 To Tw-1 Do
    If BM[Ty,Tx]=1 Then Begin
     If OnPx(Ty-1,Tx,Tw,H,At) And OnPx(Ty+1,Tx,Tw,H,At) And OnPx(Ty,Tx-1,Tw,H,At)
        And OnPx(Ty,Tx+1,Tw,H,At) Then BM[Ty,Tx]:=2;
    End;
  For Ty:=0 To H-1 Do
   For Tx:=0 To Tw-1 Do If BM[Ty,Tx]=2 Then BM[Ty,Tx]:=0;
 End;
 For Ty:=0 To H-1 Do Begin
  Sh:=0;
  If (At And A_ITAL)<>0 Then Sh:=(H-1-Ty) Div 4;
  Tx:=0;
  While Tx<Tw Do Begin
   On:=BM[Ty,Tx]<>0;
   If On And ((At And A_LIGHT)<>0) And Odd(Tx+Ty) Then On:=False;
   If On Then Begin
    Run:=Tx;
    If (At And A_LIGHT)=0 Then
     While (Run+1<Tw) And (BM[Ty,Run+1]<>0) Do Inc(Run);
    LRect(X+Sh+Tx,Y+Ty,X+Sh+Run,Y+Ty,Col);
    Tx:=Run+1;
   End Else Inc(Tx);
  End;
 End;
End;

Function ColOf(Fn: Byte): Integer;
Var C: Integer;
Begin
 C:=Fn Shr 4;
 If C>8 Then C:=1;
 ColOf:=ColMap[C];
End;

{ Dessine la ligne I de l'histoire S ; (RgOX,RgOY) = origine du texte (px region) }
Procedure DrawTextLine(S: Integer; L: PLineArr; I: Integer);
Var K,Ls,Ee,Nn,Sa,Sb,H,Hn,Bl,Top,Gx,Gy,UX1,UX2,UC,D,Dg: Integer;
 X1,X2: LongInt; C: Byte; Sel: Boolean; Col: Integer; Nm: String;
 Lh: LongInt;
Begin
 LineXs(S,L,I);
 Ls:=L^[I].S;Ee:=L^[I].E;Nn:=L^[I].N;
 If Nn-Ls>398 Then Nn:=Ls+398;
 Top:=RgOY+D2P(L^[I].Y);
 Lh:=D2P(L^[I].H);
 Bl:=Top+D2P(L^[I].Asc);
 Sa:=-1;Sb:=-1;
 If (SelA>=0) And (S=ASt) And (SelA<>Cur) And Not NoSel Then Begin
  Sa:=SelA;Sb:=Cur;
  If Sa>Sb Then Begin K:=Sa;Sa:=Sb;Sb:=K;End;
 End;
 If Sa>=0 Then
  For K:=Ls To Nn-1 Do
   If (K>=Sa) And (K<Sb) Then Begin
    X1:=RgOX+D2P(LXs[K-Ls]);X2:=RgOX+D2P(LXs[K-Ls+1])-1;
    If (St[S].T^[K]=13) Or (K>=St[S].Len) Then X2:=X1+3;
    If X2<X1 Then X2:=X1;
    LRect(X1,Top,X2,Top+Lh-1,INK);
   End;
 UX1:=-1;UC:=INK;UX2:=0;
 For K:=Ls To Ee-1 Do Begin
  C:=St[S].T^[K];
  Sel:=(Sa>=0) And (K>=Sa) And (K<Sb);
  Col:=ColOf(St[S].F^[K]);
  If Sel Then Col:=PAPER;
  H:=D2P(CellD(St[S].F^[K],St[S].A^[K]));
  Gy:=Bl-H*7 Div 8;
  If (St[S].A^[K] And A_SUP)<>0 Then Gy:=Gy-D2P(CellD(St[S].F^[K],0)*4 Div 10)
  Else If (St[S].A^[K] And A_SUB)<>0 Then Gy:=Gy+D2P(CellD(St[S].F^[K],0)*15 Div 100);
  Gx:=RgOX+D2P(LXs[K-Ls]);
  If C=1 Then Begin
   Nm:=IntStr(DrawPage+PgStart-1);
   For D:=1 To Length(Nm) Do
    DrawGlyph(Ord(Nm[D]),Gx+(D-1)*D2P(ChW(48,St[S].F^[K],St[S].A^[K])),Gy,H,St[S].A^[K],Col);
  End Else If (C<>32) And (C<>9) And (C<>10) And (C<>13) And (C<>12) Then
   DrawGlyph(C,Gx,Gy,H,St[S].A^[K],Col);
  { soulignement }
  If (St[S].A^[K] And A_UND)<>0 Then Begin
   If UX1<0 Then Begin UX1:=Gx;UC:=Col;End;
   UX2:=RgOX+D2P(LXs[K-Ls+1])-1;
   If (K=Ee-1) Or ((St[S].A^[K+1] And A_UND)=0) Then Begin
    LRect(UX1,Bl+1,UX2,Bl+1,UC);
    UX1:=-1;
   End;
  End Else UX1:=-1;
 End;
 If (L^[I].Fl And 1)<>0 Then Begin
  K:=Ee-1;
  H:=D2P(CellD(St[S].F^[K],St[S].A^[K]));
  DrawGlyph(45,RgOX+D2P(LXs[Ee-Ls]),Bl-H*7 Div 8,H,St[S].A^[K],ColOf(St[S].F^[K]));
 End;
End;

{ ====================================================================== }
{                        LISTES ET BOITES DE DIALOGUE                    }
{ ====================================================================== }

Const
 MAXCTL = 40;
 C_LABEL = 1;
 C_EDIT  = 2;
 C_CHECK = 3;
 C_RADIO = 4;
 C_BTN   = 5;
 C_POP   = 6;
 C_GROUP = 7;
 C_SWATCH= 8;

Var
 DC      : Array[1..MAXCTL] Of TCtl;
 NDC     : Integer;
 DlgX,DlgY,DlgW,DlgH : Integer;
 DlgTitle: String[40];
 DlgFocus: Integer;
 DlgId   : Integer;
 DlgFresh: Boolean;

Procedure DrawAll; Forward;
Procedure DlgApply(Id: Integer); Forward;
Procedure DlgRevert(Id: Integer); Forward;
Procedure BuildDlg(Id: Integer); Forward;

Function ListCount(L: Integer): Integer;
Begin
 Case L Of
  1: ListCount:=6;
  2: ListCount:=4;
  3: ListCount:=NFmt+1;
  4: ListCount:=4;
  5: ListCount:=10;
  6: ListCount:=17;
  7: ListCount:=11;
  8: ListCount:=3;
  Else ListCount:=0;
 End;
End;

Function ListItem(L,I: Integer): String;
Begin
 ListItem:='';
 Case L Of
  1: Case I Of
      1: ListItem:='Allemand';
      2: ListItem:='Fran'#135'ais';
      3: ListItem:='Italien';
      4: ListItem:='Anglais';
      5: ListItem:='Espagnol';
      6: ListItem:='Turc';
     End;
  2: Case I Of
      1: ListItem:='Format: DIN A4';
      2: ListItem:='Format: DIN A5';
      3: ListItem:='Format: DIN A3';
      4: ListItem:='Format: Lettre US';
     End;
  3: If I=1 Then ListItem:='Aucun format' Else ListItem:=Fmts[I-1].Name;
  4: ListItem:=IntStr(I);
  5: ListItem:='F'+IntStr(I);
  6: If I=1 Then ListItem:='(aucune)'
     Else ListItem:=FamName[(I-2) Div 8]+' '+IntStr(SizeTab[(I-2) Mod 8]);
  7: Case I Of
      1: ListItem:='(aucun)';
      2: ListItem:='gras';
      3: ListItem:='soulign'#130;
      4: ListItem:='italique';
      5: ListItem:='contour';
      6: ListItem:='clair';
      7: ListItem:='exposant';
      8: ListItem:='indice';
      9: ListItem:='interligne 16';
      10: ListItem:='nouvelle ligne';
      11: ListItem:='marquer (s'#130'lection)';
     End;
  8: Case I Of
      1: ListItem:='Normal';
      2: ListItem:='Gras';
      3: ListItem:='Italique';
     End;
 End;
End;

{ Liste deroulante : retourne l'element choisi (1..n) ou 0 }
Function PopupAt(X,Y,W,L,Cur: Integer): Integer;
Var N,I,H,Hi,Res: Integer; E: TEvent; Done,Redraw,Armed: Boolean; Y1: Integer;
Begin
 Armed:=False;
 N:=ListCount(L);
 H:=N*16+4;
 If Y+H>SCR_H-2 Then Y:=SCR_H-2-H;
 If Y<MENU_H Then Y:=MENU_H;
 If X+W>SCR_W-2 Then X:=SCR_W-2-W;
 Hi:=Cur;Res:=0;Done:=False;Redraw:=True;
 Repeat
  If Redraw Then Begin
   HideMouse;
   Box(X+3,Y+3,X+W+3,Y+H+3,INK);
   Box(X,Y,X+W,Y+H,PAPER);
   Frame(X,Y,X+W,Y+H);
   For I:=1 To N Do Begin
    Y1:=Y+2+(I-1)*16;
    If I=Hi Then Begin
     Box(X+1,Y1,X+W-1,Y1+15,INK);
     WText(X+20,Y1+4,ListItem(L,I));
    End Else PText(X+20,Y1+4,ListItem(L,I));
    If I=Cur Then Begin
     If I=Hi Then WText(X+5,Y1+4,#251) Else PText(X+5,Y1+4,#251);
    End;
   End;
   ShowMouse;
   Redraw:=False;
  End;
  PollEvent(E);
  Case E.Kind Of
   4: Begin
       Armed:=True;
       If InBox(E.X,E.Y,X,Y+2,X+W,Y+H-2) Then I:=(E.Y-Y-2) Div 16+1 Else I:=0;
       If I>N Then I:=N;
       If I<>Hi Then Begin Hi:=I;Redraw:=True;End;
      End;
   2: Begin
       If InBox(E.X,E.Y,X,Y+2,X+W,Y+H-2) Then Res:=(E.Y-Y-2) Div 16+1;
       If Res>N Then Res:=N;
       Done:=True;
      End;
   3: If Armed And InBox(E.X,E.Y,X,Y+2,X+W,Y+H-2) And (Hi>0) Then Begin Res:=Hi;Done:=True;End;
   1: Case E.Key Of
       K_ESC: Done:=True;
       K_UP: Begin If Hi>1 Then Dec(Hi) Else Hi:=N;Redraw:=True;End;
       K_DOWN: Begin If (Hi<N) And (Hi>0) Then Inc(Hi) Else Hi:=1;Redraw:=True;End;
       K_ENTER: Begin Res:=Hi;Done:=True;End;
      End;
  End;
 Until Done;
 NeedDraw:=True;
 PopupAt:=Res;
End;

Procedure DlgInit(Id,W,H: Integer; Const Title: String);
Begin
 DlgId:=Id;NDC:=0;DlgW:=W;DlgH:=H;DlgTitle:=Title;
 DlgX:=(SCR_W-W) Div 2;DlgY:=(SCR_H-H) Div 2-8;
 DlgFocus:=0;DlgFresh:=True;
End;

Function AddCtl(Kind,Id,X,Y,W,H: Integer; Const Txt: String): Integer;
Begin
 If NDC<MAXCTL Then Inc(NDC);
 FillChar(DC[NDC],SizeOf(TCtl),0);
 DC[NDC].Kind:=Kind;DC[NDC].Id:=Id;DC[NDC].X:=X;DC[NDC].Y:=Y;
 DC[NDC].W:=W;DC[NDC].H:=H;DC[NDC].Txt:=Txt;DC[NDC].On:=True;
 AddCtl:=NDC;
End;

Procedure CLabel(X,Y: Integer; Const T: String);
Var I: Integer;
Begin
 I:=AddCtl(C_LABEL,0,X,Y,TextW(T),10,T);
End;

Procedure CEdit(Id,X,Y,W: Integer; Const Init,Sfx: String; Numeric: Boolean);
Var I: Integer;
Begin
 I:=AddCtl(C_EDIT,Id,X,Y,W,16,'');
 DC[I].Str:=Init;DC[I].Sfx:=Sfx;DC[I].Num:=Numeric;
 If DlgFocus=0 Then DlgFocus:=I;
End;

Procedure CCheck(Id,X,Y: Integer; Const T: String; On: Boolean);
Var I: Integer;
Begin
 I:=AddCtl(C_CHECK,Id,X,Y,TextW(T)+20,14,T);
 DC[I].Val:=Ord(On);
End;

Procedure CRadio(Id,Grp,Val,X,Y: Integer; Const T: String; Sel: Boolean);
Var I: Integer;
Begin
 I:=AddCtl(C_RADIO,Id,X,Y,TextW(T)+20,14,T);
 DC[I].Grp:=Grp;DC[I].Val:=Val;DC[I].On:=Sel;
End;

Procedure CButton(Code,X,Y,W,H: Integer; Const T: String; Def,Enab: Boolean);
Var I: Integer;
Begin
 I:=AddCtl(C_BTN,Code,X,Y,W,H,T);
 DC[I].Num:=Def;DC[I].On:=Enab;
End;

Procedure CPopup(Id,X,Y,W,L,Cur: Integer);
Var I: Integer;
Begin
 I:=AddCtl(C_POP,Id,X,Y,W,18,'');
 DC[I].Grp:=L;DC[I].Val:=Cur;
End;

Procedure CGroup(X,Y,W,H: Integer; Const T: String);
Var I: Integer;
Begin
 I:=AddCtl(C_GROUP,0,X,Y,W,H,T);
End;

Procedure CSwatch(X,Y,Col: Integer);
Var I: Integer;
Begin
 I:=AddCtl(C_SWATCH,0,X,Y,14,14,'');
 DC[I].Val:=Col;
End;

Function CtlIdx(Id: Integer): Integer;
Var I: Integer;
Begin
 CtlIdx:=0;
 For I:=1 To NDC Do If (DC[I].Id=Id) And (DC[I].Kind<>C_BTN) Then Begin CtlIdx:=I;Exit;End;
End;

Function CStr(Id: Integer): String;
Var I: Integer;
Begin
 I:=CtlIdx(Id);
 If I>0 Then CStr:=DC[I].Str Else CStr:='';
End;

Function CNum(Id: Integer; Def: LongInt): LongInt;
Begin
 CNum:=ValInt(CStr(Id),Def);
End;

Function CChk(Id: Integer): Boolean;
Var I: Integer;
Begin
 I:=CtlIdx(Id);
 CChk:=(I>0) And (DC[I].Val<>0);
End;

Function CVal(Id: Integer): Integer;
Var I: Integer;
Begin
 I:=CtlIdx(Id);
 If I>0 Then CVal:=DC[I].Val Else CVal:=0;
End;

{ valeur du bouton radio selectionne du groupe G }
Function CRad(G: Integer): Integer;
Var I: Integer;
Begin
 CRad:=0;
 For I:=1 To NDC Do
  If (DC[I].Kind=C_RADIO) And (DC[I].Grp=G) And DC[I].On Then CRad:=DC[I].Val;
End;

Procedure DlgDraw;
Var I,X,Y,W,H,Cx,Cy: Integer; S: String;
Begin
 HideMouse;
 Box(DlgX,DlgY,DlgX+DlgW,DlgY+DlgH,PAPER);
 Frame(DlgX,DlgY,DlgX+DlgW,DlgY+DlgH);
 Frame(DlgX+1,DlgY+1,DlgX+DlgW-1,DlgY+DlgH-1);
 Frame(DlgX+2,DlgY+2,DlgX+DlgW-2,DlgY+DlgH-2);
 { barre de titre }
 PatBar(DlgX+3,DlgY+3,DlgX+DlgW-3,DlgY+TBH,PatTrack);
 SetColor(INK);
 Line(DlgX+3,DlgY+TBH+1,DlgX+DlgW-3,DlgY+TBH+1);
 Box(DlgX+3,DlgY+3,DlgX+22,DlgY+TBH,PAPER);
 Frame(DlgX+3,DlgY+3,DlgX+22,DlgY+TBH);
 Frame(DlgX+8,DlgY+8,DlgX+17,DlgY+TBH-5);
 Box((DlgX+DlgW-TextW(DlgTitle)) Div 2-6,DlgY+5,
   (DlgX+DlgW+TextW(DlgTitle)) Div 2+6,DlgY+TBH-2,PAPER);
 BText((DlgX+DlgW-TextW(DlgTitle)) Div 2,DlgY+9,DlgTitle);
 For I:=1 To NDC Do Begin
  X:=DlgX+DC[I].X;Y:=DlgY+DC[I].Y;W:=DC[I].W;H:=DC[I].H;
  Case DC[I].Kind Of
   C_LABEL: UText(X,Y,DC[I].Txt,INK);
   C_GROUP: Begin
     Frame(X,Y+4,X+W,Y+H);
     Box(X+8,Y,X+16+TextW(DC[I].Txt),Y+9,PAPER);
     UText(X+12,Y,DC[I].Txt,INK);
    End;
   C_EDIT: Begin
     Box(X,Y,X+W,Y+H,PAPER);
     Frame(X,Y,X+W,Y+H);
     S:=DC[I].Str;
     If (I=DlgFocus) And DlgFresh And (S<>'') Then Begin
      Box(X+2,Y+2,X+4+TextW(S),Y+H-2,INK);
      WText(X+3,Y+4,S);
     End Else Begin
      PText(X+3,Y+4,S);
      If I=DlgFocus Then Line(X+3+TextW(S),Y+3,X+3+TextW(S),Y+H-3);
     End;
     If DC[I].Sfx<>'' Then PText(X+W+8,Y+4,DC[I].Sfx);
    End;
   C_CHECK: Begin
     Box(X,Y,X+12,Y+12,PAPER);Frame(X,Y,X+12,Y+12);
     If DC[I].Val<>0 Then Begin
      Line(X+2,Y+2,X+10,Y+10);Line(X+10,Y+2,X+2,Y+10);
     End;
     UText(X+20,Y+3,DC[I].Txt,INK);
    End;
   C_RADIO: Begin
     Cx:=X+6;Cy:=Y+6;
     SetColor(INK);
     Circle(Cx,Cy,6);
     If DC[I].On Then Begin SetFill(INK);FillEllipse(Cx,Cy,3,3);End;
     UText(X+20,Y+3,DC[I].Txt,INK);
    End;
   C_BTN: Button(X,Y,X+W,Y+H,DC[I].Txt,DC[I].Num,DC[I].On);
   C_POP: Begin
     Box(X+3,Y+3,X+W+3,Y+H+3,INK);
     Box(X,Y,X+W,Y+H,PAPER);Frame(X,Y,X+W,Y+H);
     S:=ListItem(DC[I].Grp,DC[I].Val);
     UText((X+X+W-TextW(S)) Div 2,Y+5,S,INK);
    End;
   C_SWATCH: Begin
     Box(X,Y,X+13,Y+13,ColMap[DC[I].Val]);Frame(X,Y,X+13,Y+13);
    End;
  End;
 End;
 ShowMouse;
End;

Procedure DlgNextEdit(Dir: Integer);
Var I,K: Integer;
Begin
 If DlgFocus=0 Then Exit;
 I:=DlgFocus;
 For K:=1 To NDC Do Begin
  I:=I+Dir;
  If I>NDC Then I:=1;
  If I<1 Then I:=NDC;
  If DC[I].Kind=C_EDIT Then Begin DlgFocus:=I;DlgFresh:=True;Exit;End;
 End;
End;

{ Boucle de dialogue ; retourne le code du bouton ferme (1 OK, 2 annuler) }
Function RunDialog: Integer;
Var E: TEvent; Done,Redraw: Boolean; Res,I,X,Y,L,Sel: Integer;
Begin
 Done:=False;Redraw:=True;Res:=2;
 Repeat
  If Redraw Then Begin DlgDraw;Redraw:=False;End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   Case E.Key Of
    K_ESC: Begin Res:=2;Done:=True;End;
    K_ENTER: Begin Res:=1;Done:=True;End;
    K_TAB,K_DOWN: Begin DlgNextEdit(1);Redraw:=True;End;
    K_STAB,K_UP: Begin DlgNextEdit(-1);Redraw:=True;End;
    K_BKSP,K_DEL: If (DlgFocus>0) And (DC[DlgFocus].Kind=C_EDIT) Then Begin
      If DlgFresh Or (E.Key=K_DEL) Then DC[DlgFocus].Str:=''
      Else If Length(DC[DlgFocus].Str)>0 Then Dec(DC[DlgFocus].Str[0]);
      DlgFresh:=False;Redraw:=True;
     End;
    32..255: If (DlgFocus>0) And (DC[DlgFocus].Kind=C_EDIT) Then Begin
      If DlgFresh Then DC[DlgFocus].Str:='';
      DlgFresh:=False;
      If (Not DC[DlgFocus].Num) Or (Chr(E.Key) In ['0'..'9','-']) Then
       If TextW(DC[DlgFocus].Str)+8<DC[DlgFocus].W-4 Then
        DC[DlgFocus].Str:=DC[DlgFocus].Str+Chr(E.Key);
      Redraw:=True;
     End;
   End;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,DlgX+3,DlgY+3,DlgX+22,DlgY+TBH) Then Begin Res:=2;Done:=True;End
   Else For I:=1 To NDC Do Begin
    X:=DlgX+DC[I].X;Y:=DlgY+DC[I].Y;
    If (DC[I].Kind In [C_EDIT,C_CHECK,C_RADIO,C_BTN,C_POP]) And
       InBox(E.X,E.Y,X,Y,X+DC[I].W,Y+DC[I].H) Then Begin
     Case DC[I].Kind Of
      C_EDIT: Begin DlgFocus:=I;DlgFresh:=False;Redraw:=True;End;
      C_CHECK: Begin DC[I].Val:=1-DC[I].Val;Redraw:=True;End;
      C_RADIO: Begin
        For L:=1 To NDC Do
         If (DC[L].Kind=C_RADIO) And (DC[L].Grp=DC[I].Grp) Then DC[L].On:=False;
        DC[I].On:=True;Redraw:=True;
       End;
      C_POP: Begin
        Sel:=PopupAt(X,Y,DC[I].W,DC[I].Grp,DC[I].Val);
        If Sel>0 Then DC[I].Val:=Sel;
        DrawAll;Redraw:=True;
       End;
      C_BTN: If DC[I].On Then Begin
        Res:=DC[I].Id;
        If Res=3 Then Begin
         DlgApply(DlgId);DrawAll;Redraw:=True;
        End Else If Res=4 Then Begin
         DlgRevert(DlgId);DrawAll;Redraw:=True;
        End Else Done:=True;
       End;
     End;
     Break;
    End;
   End;
  End;
 Until Done;
 NeedDraw:=True;
 RunDialog:=Res;
End;

Procedure MsgBox(Const Title,Txt: String);
Var Lines: Array[1..12] Of String[60]; N,I,W,P: Integer; S: String;
Begin
 N:=0;S:=Txt;W:=TextW(Title)+80;
 While (S<>'') And (N<12) Do Begin
  P:=Pos('|',S);
  Inc(N);
  If P=0 Then Begin Lines[N]:=Copy(S,1,60);S:='';End
  Else Begin Lines[N]:=Copy(S,1,P-1);Delete(S,1,P);End;
  If TextW(Lines[N])+40>W Then W:=TextW(Lines[N])+40;
 End;
 If W<240 Then W:=240;
 DlgInit(99,W,N*12+TBH+60,Title);
 For I:=1 To N Do CLabel(20,TBH+14+(I-1)*12,Lines[I]);
 CButton(1,(W-70) Div 2,N*12+TBH+26,70,20,'OK',True,True);
 RunDialog;
End;

Function ConfirmBox(Const Txt: String): Boolean;
Var W: Integer;
Begin
 W:=TextW(Txt)+40;
 If W<260 Then W:=260;
 DlgInit(98,W,TBH+80,'Papyrus');
 CLabel(20,TBH+16,Txt);
 CButton(1,20,TBH+44,80,20,'&Oui',True,True);
 CButton(2,W-100,TBH+44,80,20,'&Non',False,True);
 ConfirmBox:=RunDialog=1;
End;

Function InputBox(Const Title,Prompt: String; Var S: String; MaxLen: Integer): Boolean;
Var W: Integer;
Begin
 W:=TextW(Prompt)+MaxLen*8+60;
 If W<300 Then W:=300;
 If W>600 Then W:=600;
 DlgInit(97,W,TBH+80,Title);
 CLabel(16,TBH+14,Prompt);
 CEdit(1,16,TBH+30,W-32,S,'',False);
 CButton(1,16,TBH+54,80,20,'OK',True,True);
 CButton(2,W-96,TBH+54,80,20,'&Annuler',False,True);
 If RunDialog=1 Then Begin
  S:=CStr(1);InputBox:=True;
 End Else InputBox:=False;
End;

{ ====================================================================== }
{                              MENUS                                     }
{ ====================================================================== }

Const
 MTitle : Array[1..NMENU] Of String[8] = ('papyrus','Fichier','Imprimer',
   'Edition','Texte','Style','Objet','Zoom','Options');

Procedure DoMenu(M,I: Integer); Forward;

Function MCount(M: Integer): Integer;
Begin
 Case M Of
  1: MCount:=4;
  2: MCount:=9;
  3: MCount:=5;
  4: MCount:=13;
  5: MCount:=14;
  6: MCount:=20;
  7: MCount:=14;
  8: MCount:=8;
  9: MCount:=8;
  Else MCount:=0;
 End;
End;

{ '-' = separateur ; '|' separe le raccourci }
Function MLabel(M,I: Integer): String;
Begin
 MLabel:='';
 Case M Of
  1: Case I Of
      1: MLabel:=#192' propos de Papyrus...';
      2: MLabel:='-';
      3: MLabel:='Statistiques...';
      4: MLabel:='M'#130'moire libre';
     End;
  2: Case I Of
      1: MLabel:='Nouveau|^N';
      2: MLabel:='Ouvrir...|^O';
      3: MLabel:='Enregistrer|^S';
      4: MLabel:='Enregistrer sous...';
      5: MLabel:='-';
      6: MLabel:='Importer texte ASCII...';
      7: MLabel:='Exporter texte ASCII...';
      8: MLabel:='-';
      9: MLabel:='Quitter|^Q';
     End;
  3: Case I Of
      1: MLabel:='Imprimer le document|^P';
      2: MLabel:='Imprimer la page';
      3: MLabel:='-';
      4: MLabel:='Aper'#135'u avant impression';
      5: MLabel:='Destination...';
     End;
  4: Case I Of
      1: MLabel:='Annuler|^Z';
      2: MLabel:='-';
      3: MLabel:='Couper|^X';
      4: MLabel:='Copier|^C';
      5: MLabel:='Coller|^V';
      6: MLabel:='Effacer|Suppr';
      7: MLabel:='Tout s'#130'lectionner|^A';
      8: MLabel:='-';
      9: MLabel:='Chercher...|^F';
      10: MLabel:='Remplacer...|^W';
      11: MLabel:='Chercher suivant|^G';
      12: MLabel:='-';
      13: MLabel:='Aller '#133' la page...|^T';
     End;
  5: Case I Of
      1: MLabel:='Mise en page...';
      2: MLabel:='D'#130'calages de page...';
      3: MLabel:='C'#130'sure...';
      4: MLabel:='-';
      5: MLabel:='Paragraphe...';
      6: MLabel:='Formats...';
      7: MLabel:='-';
      8: MLabel:='Gauche|^L';
      9: MLabel:='Justifi'#130'|^D';
      10: MLabel:='Centr'#130'|^E';
      11: MLabel:='Droite|^R';
      12: MLabel:='-';
      13: MLabel:='Saut de page';
      14: MLabel:='Num'#130'ro de page';
     End;
  6: Case I Of
      1: MLabel:='Normal';
      2: MLabel:='Gras|^B';
      3: MLabel:='Italique|F3';
      4: MLabel:='Soulign'#130'|^U';
      5: MLabel:='Contour|F4';
      6: MLabel:='Clair|F5';
      7: MLabel:='Exposant|F6';
      8: MLabel:='Indice|F7';
      9: MLabel:='-';
      10: MLabel:='Times 8';
      11: MLabel:='Times 10';
      12: MLabel:='Times 12';
      13: MLabel:='Times 14';
      14: MLabel:='Swiss 8';
      15: MLabel:='Swiss 10';
      16: MLabel:='Swiss 12';
      17: MLabel:='Swiss 14';
      18: MLabel:='-';
      19: MLabel:='Autre taille...';
      20: MLabel:='Couleur...';
     End;
  7: Case I Of
      1: MLabel:='Cadre de texte';
      2: MLabel:='Rectangle';
      3: MLabel:='Rectangle fonc'#130;
      4: MLabel:='Rectangle gris';
      5: MLabel:='Ligne';
      6: MLabel:='Image (PBM)...';
      7: MLabel:='-';
      8: MLabel:='Attributs...';
      9: MLabel:='Angle du texte...';
      10: MLabel:='Couleur...';
      11: MLabel:='-';
      12: MLabel:='Premier plan';
      13: MLabel:='Arri'#138're-plan';
      14: MLabel:='Supprimer l''objet';
     End;
  8: Case I Of
      1: MLabel:='50 %';
      2: MLabel:='75 %';
      3: MLabel:='100 %';
      4: MLabel:='150 %';
      5: MLabel:='200 %';
      6: MLabel:='-';
      7: MLabel:='Page enti'#138're';
      8: MLabel:='Largeur de page';
     End;
  9: Case I Of
      1: MLabel:='Palette d''outils';
      2: MLabel:='R'#138'gle';
      3: MLabel:='Barre de format';
      4: MLabel:='Rep'#138'res de marges';
      5: MLabel:='-';
      6: MLabel:='Touches de fonction...';
      7: MLabel:='-';
      8: MLabel:='Enregistrer la config.';
     End;
 End;
End;

Function MChecked(M,I: Integer): Boolean;
Begin
 MChecked:=False;
 If (M=3) And (I=4) Then MChecked:=Preview;
 If M=8 Then Begin
  If (I=1) And (Zoom=50) Then MChecked:=True;
  If (I=2) And (Zoom=75) Then MChecked:=True;
  If (I=3) And (Zoom=100) Then MChecked:=True;
  If (I=4) And (Zoom=150) Then MChecked:=True;
  If (I=5) And (Zoom=200) Then MChecked:=True;
 End;
 If M=9 Then Begin
  If I=1 Then MChecked:=ToolsOn;
  If I=2 Then MChecked:=RulerOn;
  If I=3 Then MChecked:=FormatOn;
  If I=4 Then MChecked:=GuidesOn;
 End;
 If (M=5) And (I In [8..11]) Then
  MChecked:=(St[ASt].Pa^[ParaOf(ASt,Cur)].Al=I-8);
End;

Function MEnabled(M,I: Integer): Boolean;
Begin
 MEnabled:=True;
 If (M=4) And (I=1) Then MEnabled:=UndoOK;
 If (M=4) And (I In [3,4,6]) Then MEnabled:=(SelA>=0) And (SelA<>Cur);
 If (M=4) And (I=5) Then MEnabled:=ClipN>0;
 If (M=7) And (I In [8,9,12,13,14]) Then MEnabled:=SelObj>0;
 If (M=7) And (I=9) Then MEnabled:=(SelObj>0) And (Obj[SelObj].Kind=OB_TEXT);
End;

Function MSep(M,I: Integer): Boolean;
Begin
 MSep:=(MLabel(M,I)='-');
End;

Function MenuX(M: Integer): Integer;
Var I,X: Integer;
Begin
 X:=24;
 For I:=1 To M-1 Do X:=X+Length(MTitle[I])*8+16;
 MenuX:=X;
End;

Function ItemH(M,I: Integer): Integer;
Begin
 If MSep(M,I) Then ItemH:=8 Else ItemH:=16;
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
 X1:=MenuX(M)-8;
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
  If (X>=MenuX(M)-8) And (X<=MenuX(M)+Length(MTitle[M])*8+7) Then TitleHit:=M;
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
   Box(MenuX(M)-8,0,MenuX(M)+Length(MTitle[M])*8+7,MENU_H-2,INK);
   WText(MenuX(M),5,MTitle[M]);
  End Else BText(MenuX(M),5,MTitle[M]);
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

{ ====================================================================== }
{                   GEOMETRIE DE LA FENETRE ET BARRES                    }
{ ====================================================================== }

Var
 RulY1,TbY1 : Integer;
 FKTxt  : Array[1..10,1..2] Of String[9];

Procedure CalcGeo;
Var RH,TH: Integer;
Begin
 If ToolsOn And Not FullWin Then WX1:=PALW+10 Else WX1:=0;
 WX2:=SCR_W-11;
 WY1:=MENU_H+1;WY2:=FKEY_Y-4;
 If RulerOn Then RH:=14 Else RH:=0;
 If FormatOn Then TH:=42 Else TH:=0;
 RulY1:=WY1+TBH+1;
 TbY1:=RulY1+RH;
 VX1:=WX1+1;VX2:=WX2-SBW-1;
 VY1:=TbY1+TH+1;VY2:=WY2-SBW-1;
End;

Function DocHeight: LongInt;
Begin
 DocHeight:=LongInt(NPages)*StridePx+8;
End;

Function MaxScrY: LongInt;
Begin
 MaxScrY:=Max2(0,DocHeight-(VY2-VY1+1));
End;

Function MaxScrX: LongInt;
Begin
 MaxScrX:=Max2(0,PageWPx+14-(VX2-VX1+1));
End;

Procedure ClampScroll;
Begin
 If ScrY>MaxScrY Then ScrY:=MaxScrY;
 If ScrY<0 Then ScrY:=0;
 If ScrX>MaxScrX Then ScrX:=MaxScrX;
 If ScrX<0 Then ScrX:=0;
End;

{ Page visible en haut de la vue }
Function TopPage: Integer;
Var P: LongInt;
Begin
 P:=(ScrY+(VY2-VY1) Div 3) Div StridePx+1;
 If P<1 Then P:=1;
 If P>NPages Then P:=NPages;
 TopPage:=P;
End;

{ Positionne le contexte de dessin sur un cadre (dmm, page P) }
Procedure SetRegion(P,Xd,Yd,Wd,Hd,Ang,Pad: Integer);
Begin
 FrX:=PageX0+D2P(Xd);FrY:=PageY0(P)+D2P(Yd);
 FrW:=D2P(Wd);FrH:=D2P(Hd);
 RgAng:=Ang;RgOX:=Pad;RgOY:=Pad;
 CX1:=Max2(VX1,FrX);CY1:=Max2(VY1,FrY);
 CX2:=Min2(VX2,FrX+FrW-1);CY2:=Min2(VY2,FrY+FrH-1);
End;

Procedure ViewClip;
Begin
 CX1:=VX1;CY1:=VY1;CX2:=VX2;CY2:=VY2;
End;

{ Region (page, cadre) d'une ligne de l'histoire S }
Procedure RegionOf(S: Integer; L: PLineArr; I: Integer;
  Var Pg,Xd,Yd,Wd,Hd,Ang,Pad: Integer);
Var O,Reg: Integer;
Begin
 Ang:=0;Pad:=0;
 If S=0 Then Begin
  Reg:=L^[I].Reg;
  Pg:=Reg Div NCols+1;
  Xd:=BodyX(Pg)+(Reg Mod NCols)*(ColWd+ColGap*10);
  Yd:=BodyYd;Wd:=ColWd;Hd:=BodyHd;
 End Else If S=1 Then Begin
  Pg:=CurPg;Xd:=BodyX(Pg);Yd:=MarT*10;Wd:=TextWd;Hd:=HeadH*10;
 End Else If S=2 Then Begin
  Pg:=CurPg;Xd:=BodyX(Pg);Yd:=PgH-(MarB+FootH)*10;Wd:=TextWd;Hd:=FootH*10;
 End Else Begin
  O:=ObjOfStory(S);
  Pg:=Obj[O].Pg;Xd:=Obj[O].X;Yd:=Obj[O].Y;Wd:=Obj[O].W;Hd:=Obj[O].H;
  Ang:=Obj[O].Ang And 3;Pad:=D2P(20);
 End;
End;

Procedure DotH(X1,X2,Y: LongInt);
Var X: LongInt;
Begin
 X:=X1;
 While X<=X2 Do Begin CBar(X,Y,X,Y,INK);X:=X+4;End;
End;

Procedure DotV(X,Y1,Y2: LongInt);
Var Y: LongInt;
Begin
 Y:=Y1;
 While Y<=Y2 Do Begin CBar(X,Y,X,Y,INK);Y:=Y+4;End;
End;

Procedure DrawPatRect(X1,Y1,X2,Y2: LongInt; Fill: Byte);
Begin
 If X1<CX1 Then X1:=CX1;
 If Y1<CY1 Then Y1:=CY1;
 If X2>CX2 Then X2:=CX2;
 If Y2>CY2 Then Y2:=CY2;
 If (X1>X2) Or (Y1>Y2) Then Exit;
 Case Fill Of
  1: PatBar(X1,Y1,X2,Y2,PatLight);
  2: PatBar(X1,Y1,X2,Y2,PatChecker);
  3: PatBar(X1,Y1,X2,Y2,PatDark);
  4: Box(X1,Y1,X2,Y2,INK);
 End;
End;

Procedure DrawImage(I: Integer; X1,Y1,W,H: LongInt);
Var X,Y,Sx,Sy,Bw: LongInt; B: Byte;
Begin
 If (Obj[I].Img=Nil) Or (W<2) Or (H<2) Then Begin
  DrawPatRect(X1,Y1,X1+W-1,Y1+H-1,2);
  CBar(X1+4,Y1+H Div 2-6,X1+W-5,Y1+H Div 2+6,PAPER);
  Exit;
 End;
 Bw:=(Obj[I].IW+7) Div 8;
 For Y:=Y1 To Y1+H-1 Do Begin
  If (Y<CY1) Or (Y>CY2) Then Continue;
  Sy:=(Y-Y1)*Obj[I].IH Div H;
  X:=X1;
  While X<=X1+W-1 Do Begin
   If (X<CX1) Or (X>CX2) Then Begin Inc(X);Continue;End;
   Sx:=(X-X1)*Obj[I].IW Div W;
   B:=Obj[I].Img^[Sy*Bw+Sx Shr 3];
   If (B And ($80 Shr (Sx And 7)))<>0 Then CBar(X,Y,X,Y,INK);
   Inc(X);
  End;
 End;
End;

Procedure DrawObject(I: Integer);
Var Pg,K,Bd: Integer; X1,Y1,X2,Y2: LongInt; S: String;
Begin
 Pg:=Obj[I].Pg;
 If (Pg<1) Or (Pg>NPages) Then Exit;
 SetRegion(Pg,Obj[I].X,Obj[I].Y,Obj[I].W,Obj[I].H,0,0);
 If (FrY>VY2) Or (FrY+FrH<VY1) Then Exit;
 X1:=FrX;Y1:=FrY;X2:=FrX+FrW-1;Y2:=FrY+FrH-1;
 Bd:=Obj[I].Bord;
 Case Obj[I].Kind Of
  OB_RECT: Begin
    If Obj[I].Fill>0 Then DrawPatRect(X1,Y1,X2,Y2,Obj[I].Fill);
    For K:=0 To Bd-1 Do Begin
     CBar(X1+K,Y1+K,X2-K,Y1+K,INK);CBar(X1+K,Y2-K,X2-K,Y2-K,INK);
     CBar(X1+K,Y1+K,X1+K,Y2-K,INK);CBar(X2-K,Y1+K,X2-K,Y2-K,INK);
    End;
   End;
  OB_LINE: Begin
    Y1:=FrY+FrH Div 2;
    For K:=0 To Bd-1 Do CBar(X1,Y1+K,X2,Y1+K,ColOf(Obj[I].Col*16));
   End;
  OB_IMAGE: Begin
    DrawImage(I,X1,Y1,FrW,FrH);
    CBar(X1,Y1,X2,Y1,INK);CBar(X1,Y2,X2,Y2,INK);CBar(X1,Y1,X1,Y2,INK);CBar(X2,Y1,X2,Y2,INK);
   End;
  OB_TEXT: Begin
    If Obj[I].Fill>0 Then DrawPatRect(X1,Y1,X2,Y2,Obj[I].Fill)
    Else CBar(X1,Y1,X2,Y2,PAPER);
    For K:=0 To Bd-1 Do Begin
     CBar(X1+K,Y1+K,X2-K,Y1+K,INK);CBar(X1+K,Y2-K,X2-K,Y2-K,INK);
     CBar(X1+K,Y1+K,X1+K,Y2-K,INK);CBar(X2-K,Y1+K,X2-K,Y2-K,INK);
    End;
    If Bd=0 Then Begin DotH(X1,X2,Y1);DotH(X1,X2,Y2);DotV(X1,Y1,Y2);DotV(X2,Y1,Y2);End;
    SetRegion(Pg,Obj[I].X,Obj[I].Y,Obj[I].W,Obj[I].H,Obj[I].Ang And 3,D2P(20));
    LayoutBox(Obj[I].St);
    DrawPage:=Pg;
    NoSel:=False;
    For K:=0 To NTL-1 Do DrawTextLine(Obj[I].St,TLn,K);
   End;
 End;
 ViewClip;
 If I=SelObj Then Begin
  SetRegion(Pg,Obj[I].X,Obj[I].Y,Obj[I].W,Obj[I].H,0,0);
  ViewClip;
  X1:=FrX;Y1:=FrY;X2:=FrX+FrW-1;Y2:=FrY+FrH-1;
  CBar(X1-3,Y1-3,X1+2,Y1+2,INK);CBar(X2-2,Y1-3,X2+3,Y1+2,INK);
  CBar(X1-3,Y2-2,X1+2,Y2+3,INK);CBar(X2-2,Y2-2,X2+3,Y2+3,INK);
  CBar((X1+X2) Div 2-2,Y1-3,(X1+X2) Div 2+2,Y1+2,INK);
  CBar((X1+X2) Div 2-2,Y2-2,(X1+X2) Div 2+2,Y2+3,INK);
 End;
End;

Procedure DrawHF(P: Integer);
Var S,K: Integer; Pg,Xd,Yd,Wd,Hd,Ang,Pad: Integer;
Begin
 If P<HFFrom Then Exit;
 For S:=1 To 2 Do
  If St[S].Len>0 Then Begin
   LayoutBox(S);
   If S=1 Then SetRegion(P,BodyX(P),MarT*10,TextWd,HeadH*10,0,0)
   Else SetRegion(P,BodyX(P),PgH-(MarB+FootH)*10,TextWd,FootH*10,0,0);
   DrawPage:=P;
   NoSel:=(ASt<>S) Or (P<>CurPg);
   For K:=0 To NTL-1 Do DrawTextLine(S,TLn,K);
  End;
 NoSel:=False;
End;

Procedure CaretGeom(Var Pg: Integer; Var Xd,Yd,Hd: LongInt; Var Ok: Boolean);
Var L: PLineArr; N,I,Rg,Rx,Ry,Rw,Rh,Ang,Pad: Integer;
Begin
 Ok:=False;
 GetLines(ASt,L,N);
 If N=0 Then Exit;
 I:=LineOfPos(L,N,Cur);
 CurLine:=I;
 RegionOf(ASt,L,I,Pg,Rx,Ry,Rw,Rh,Ang,Pad);
 Xd:=Rx+XOfPos(ASt,L,I,Cur);
 Yd:=Ry+L^[I].Y;
 Hd:=L^[I].H;
 Ok:=True;
End;

Procedure DrawCaret;
Var L: PLineArr; N,I,Pg,Rx,Ry,Rw,Rh,Ang,Pad: Integer; X: LongInt;
 A,B,C,D: LongInt;
Begin
 CaretOn:=False;
 If (Tool<>TL_TEXT) And (Tool<>TL_FRAME) And (Tool<>TL_SEL) Then Exit;
 If (SelA>=0) And (SelA<>Cur) Then Exit;
 GetLines(ASt,L,N);
 If N=0 Then Exit;
 I:=LineOfPos(L,N,Cur);
 RegionOf(ASt,L,I,Pg,Rx,Ry,Rw,Rh,Ang,Pad);
 If (Pg<1) Or (Pg>NPages) Then Exit;
 SetRegion(Pg,Rx,Ry,Rw,Rh,Ang,Pad);
 If (ASt>=1) And (ASt<=2) And (Pg<>CurPg) Then Exit;
 X:=XOfPos(ASt,L,I,Cur);
 MapR(RgOX+D2P(X),RgOY+D2P(L^[I].Y),RgOX+D2P(X)+1,RgOY+D2P(L^[I].Y)+D2P(L^[I].H)-1,A,B,C,D);
 ViewClip;
 If (A<VX1) Or (C>VX2) Or (B<VY1) Or (D>VY2) Then Exit;
 CBar(A,B,C,D,INK);
 CaretX:=A;CaretY1:=B;CaretY2:=D;
 CaretOn:=True;
End;

Procedure ToggleCaret;
Begin
 If Not CaretOn Then Exit;
 SetWriteMode(XORPut);
 SetColor(15);
 SetLineStyle(SolidLn,0,1);
 Line(CaretX,CaretY1,CaretX,CaretY2);
 Line(CaretX+1,CaretY1,CaretX+1,CaretY2);
 SetWriteMode(NormalPut);
End;

Procedure DrawDoc;
Var P,I,Col,K: Integer; PX0,PY0,PW,PH,X1,Y1,X2,Y2: LongInt; Ty: LongInt;
Begin
 ViewClip;
 PatBar(VX1,VY1,VX2,VY2,PatChecker);
 EnsureLayout;
 PW:=PageWPx;PH:=PageHPx;
 For P:=1 To NPages Do Begin
  PX0:=PageX0;PY0:=PageY0(P);
  If (PY0>VY2) Or (PY0+PH<VY1) Then Continue;
  ViewClip;
  CBar(PX0+PW,PY0+3,PX0+PW+2,PY0+PH+2,INK);
  CBar(PX0+3,PY0+PH,PX0+PW+2,PY0+PH+2,INK);
  CBar(PX0,PY0,PX0+PW-1,PY0+PH-1,PAPER);
  If GuidesOn And Not Preview Then Begin
   X1:=PX0+D2P(BodyX(P));X2:=X1+D2P(TextWd);
   Y1:=PY0+D2P(MarT*10);Y2:=PY0+D2P(PgH-MarB*10);
   DotH(X1,X2,Y1);DotH(X1,X2,Y2);DotV(X1,Y1,Y2);DotV(X2,Y1,Y2);
   DotH(X1,X2,PY0+D2P(BodyYd));DotH(X1,X2,PY0+D2P(PgH-(MarB+FootH)*10));
   For Col:=1 To NCols-1 Do Begin
    K:=BodyX(P)+Col*(ColWd+ColGap*10);
    DotV(PX0+D2P(K)-D2P(ColGap*5),PY0+D2P(BodyYd),PY0+D2P(PgH-(MarB+FootH)*10));
   End;
  End;
  DrawHF(P);
  { texte principal }
  DrawPage:=P;NoSel:=False;
  For I:=0 To NML-1 Do
   If (ML^[I].Reg Div NCols)+1=P Then Begin
    Col:=ML^[I].Reg Mod NCols;
    SetRegion(P,BodyX(P)+Col*(ColWd+ColGap*10),BodyYd,ColWd,BodyHd,0,0);
    Ty:=FrY+D2P(ML^[I].Y);
    If (Ty>VY2) Or (Ty+D2P(ML^[I].H)<VY1) Then Continue;
    DrawTextLine(0,ML,I);
   End;
  ViewClip;
  For I:=1 To NObj Do If Obj[I].Pg=P Then DrawObject(I);
 End;
 ViewClip;
 DrawCaret;
End;

{ ====================================================================== }
{                     FENETRE : TITRE, REGLE, FORMAT                     }
{ ====================================================================== }

Procedure DrawScrollV(X1,Y1,X2,Y2: Integer; Pos,Range: LongInt);
Var TY1,TY2,TH,TP: Integer;
Begin
 ArrowBox(X1,Y1,X2,Y1+SBW-1,1);
 ArrowBox(X1,Y2-SBW+1,X2,Y2,2);
 TY1:=Y1+SBW;TY2:=Y2-SBW;
 If TY2>TY1 Then Begin
  PatBar(X1,TY1,X2,TY2,PatChecker);
  Frame(X1,TY1-1,X2,TY2+1);
  If Range<1 Then Range:=1;
  TH:=(TY2-TY1) Div 4;If TH<14 Then TH:=14;
  TP:=TY1+(Pos*(TY2-TY1-TH)) Div Range;
  If TP<TY1 Then TP:=TY1;
  If TP+TH>TY2 Then TP:=TY2-TH;
  Box(X1,TP,X2,TP+TH,PAPER);
  Frame(X1,TP,X2,TP+TH);
 End;
End;

Procedure DrawScrollH(X1,Y1,X2,Y2: Integer; Pos,Range: LongInt);
Var TX1,TX2,TW,TP: Integer;
Begin
 ArrowBox(X1,Y1,X1+SBW-1,Y2,3);
 ArrowBox(X2-SBW+1,Y1,X2,Y2,4);
 TX1:=X1+SBW;TX2:=X2-SBW;
 If TX2>TX1 Then Begin
  PatBar(TX1,Y1,TX2,Y2,PatChecker);
  Frame(TX1-1,Y1,TX2+1,Y2);
  If Range<1 Then Range:=1;
  TW:=(TX2-TX1) Div 4;If TW<14 Then TW:=14;
  TP:=TX1+(Pos*(TX2-TX1-TW)) Div Range;
  If TP<TX1 Then TP:=TX1;
  If TP+TW>TX2 Then TP:=TX2-TW;
  Box(TP,Y1,TP+TW,Y2,PAPER);
  Frame(TP,Y1,TP+TW,Y2);
 End;
End;

Procedure DrawTitleBar;
Var T: String; X1,X2: Integer;
Begin
 PatBar(WX1,WY1,WX2,WY1+TBH,PatStripe);
 Frame(WX1,WY1,WX2,WY1+TBH);
 Box(WX1,WY1,WX1+TBH-1,WY1+TBH,PAPER);Frame(WX1,WY1,WX1+TBH-1,WY1+TBH);
 Frame(WX1+5,WY1+5,WX1+TBH-6,WY1+TBH-5);
 Box(WX2-TBH+1,WY1,WX2,WY1+TBH,PAPER);Frame(WX2-TBH+1,WY1,WX2,WY1+TBH);
 Frame(WX2-TBH+4,WY1+4,WX2-4,WY1+TBH-4);Frame(WX2-TBH+7,WY1+7,WX2-7,WY1+TBH-7);
 T:=ShortName(DocName);
 If T='' Then T:='SANS_NOM.PAP';
 If Modified Then T:=T+' *';
 Box((WX1+WX2-TextW(T)) Div 2-8,WY1+2,(WX1+WX2+TextW(T)) Div 2+8,WY1+TBH-2,PAPER);
 BText((WX1+WX2-TextW(T)) Div 2,WY1+7,T);
End;

Procedure DrawRuler;
Var X,Cm,Mm,Y2,PxCm,I,Pg: LongInt; S: String; Pr: TPara; Tx: Integer;
Begin
 If Not RulerOn Then Exit;
 Y2:=RulY1+13;
 Box(WX1+1,RulY1,WX2-SBW-1,Y2,PAPER);
 SetColor(INK);
 Line(WX1+1,Y2,WX2-SBW-1,Y2);
 ViewClip;
 CX1:=WX1+1;CX2:=WX2-SBW-1;CY1:=RulY1;CY2:=Y2;
 For Cm:=0 To 40 Do Begin
  X:=PageX0+D2P(Cm*100);
  If (X<WX1) Or (X>WX2-SBW) Then Continue;
  CBar(X,RulY1+4,X,Y2,INK);
  S:=IntStr(Cm);
  If (Cm>0) And ((D2P(100)>=16) Or ((Cm Mod 5)=0)) Then SmallText(X+2,RulY1+1,S,INK);
  If Zoom>=75 Then Begin
   Mm:=PageX0+D2P(Cm*100+50);
   CBar(Mm,RulY1+8,Mm,Y2,INK);
  End;
  If Zoom>=150 Then
   For I:=1 To 9 Do
    If I<>5 Then Begin
     Mm:=PageX0+D2P(Cm*100+I*10);
     CBar(Mm,RulY1+10,Mm,Y2,INK);
    End;
 End;
 { marges et colonnes de la page courante }
 Pg:=CurPg;
 X:=PageX0+D2P(BodyX(Pg));
 CBar(X,RulY1+2,X+2,RulY1+3,INK);
 X:=PageX0+D2P(BodyX(Pg)+TextWd);
 CBar(X-2,RulY1+2,X,RulY1+3,INK);
 { taquets de tabulation du paragraphe courant }
 Pr:=St[ASt].Pa^[ParaOf(ASt,Cur)];
 For I:=1 To Pr.NT Do Begin
  X:=PageX0+D2P(BodyX(Pg)+Pr.Tb[I].P);
  Case Pr.Tb[I].K Of
   0: Begin CBar(X,Y2-5,X,Y2-1,INK);CBar(X+1,Y2-4,X+2,Y2-2,INK);End;
   1: Begin CBar(X-2,Y2-3,X+2,Y2-3,INK);CBar(X-1,Y2-4,X+1,Y2-2,INK);End;
   2: Begin CBar(X,Y2-5,X,Y2-1,INK);CBar(X-2,Y2-4,X-1,Y2-2,INK);End;
   3: CBar(X-1,Y2-4,X+1,Y2-2,INK);
  End;
 End;
 ViewClip;
End;

{ Positions des boutons de la barre de format (relatives a WX1) }
Function TbHit(X,Y: LongInt): Integer;
Var Y1,I: Integer; Rx: LongInt;
Begin
 TbHit:=0;
 If Not FormatOn Then Exit;
 Y1:=TbY1+10;
 If (Y<Y1) Or (Y>Y1+22) Then Exit;
 Rx:=X-WX1;
 If (Rx>=19) And (Rx<=134) Then TbHit:=1;
 For I:=0 To 3 Do
  If (Rx>=143+I*34) And (Rx<=171+I*34) Then TbHit:=2+I;
 For I:=0 To 3 Do
  If (Rx>=285+I*20) And (Rx<=299+I*20) Then TbHit:=6+I;
 If (Rx>=375) And (Rx<=400) Then TbHit:=10;
 If (Rx>=432) And (Rx<=458) Then TbHit:=11;
 If (Rx>=465) And (Rx<=494) Then TbHit:=12;
 If (Rx>=550) And (Rx<=WX2-WX1-SBW) Then TbHit:=13;
End;

Procedure TbBtn(X1,Y1,X2,Y2: Integer; On: Boolean);
Begin
 If On Then Box(X1,Y1,X2,Y2,INK) Else Begin Box(X1,Y1,X2,Y2,PAPER);Frame(X1,Y1,X2,Y2);End;
End;

Procedure DrawToolbar;
Var Y1,I,X,J,C,Ln: Integer; Pr: TPara; S: String; Pn: Integer;
Begin
 If Not FormatOn Then Exit;
 Box(WX1+1,TbY1,WX2-SBW-1,TbY1+41,PAPER);
 Y1:=TbY1+10;
 Pn:=ParaOf(ASt,Cur);
 Pr:=St[ASt].Pa^[Pn];
 { icone de gauche }
 Frame(WX1+5,Y1,WX1+14,Y1+22);
 For I:=1 To 4 Do Line(WX1+7,Y1+I*4,WX1+12,Y1+I*4);
 { format }
 Box(WX1+22,Y1+3,WX1+137,Y1+25,INK);
 Box(WX1+19,Y1,WX1+134,Y1+22,PAPER);Frame(WX1+19,Y1,WX1+134,Y1+22);
 If Pr.Fm=0 Then S:='Aucun format' Else S:=Fmts[Pr.Fm].Name;
 BText(WX1+19+(116-TextW(S)) Div 2,Y1+7,S);
 { alignements }
 For I:=0 To 3 Do Begin
  X:=WX1+143+I*34;
  TbBtn(X,Y1,X+28,Y1+22,Pr.Al=I);
  If Pr.Al=I Then C:=PAPER Else C:=INK;
  SetColor(C);
  For J:=0 To 4 Do Begin
   Ln:=20;
   If (I<>1) And Odd(J) Then Ln:=12;
   Case I Of
    0,1: Line(X+4,Y1+4+J*4,X+4+Ln,Y1+4+J*4);
    2: Line(X+14-Ln Div 2,Y1+4+J*4,X+14+Ln Div 2,Y1+4+J*4);
    3: Line(X+24-Ln,Y1+4+J*4,X+24,Y1+4+J*4);
   End;
  End;
 End;
 { tabulations }
 For I:=0 To 3 Do Begin
  X:=WX1+285+I*20;
  TbBtn(X,Y1,X+14,Y1+22,TabKind=I);
  If TabKind=I Then C:=PAPER Else C:=INK;
  SetColor(C);
  SetFill(C);
  Case I Of
   0: Begin Line(X+4,Y1+5,X+4,Y1+17);Line(X+5,Y1+5,X+10,Y1+11);Line(X+5,Y1+17,X+10,Y1+11);End;
   1: FillEllipse(X+7,Y1+11,3,3);
   2: Begin Line(X+10,Y1+5,X+10,Y1+17);Line(X+9,Y1+5,X+4,Y1+11);Line(X+9,Y1+17,X+4,Y1+11);End;
   3: FillEllipse(X+7,Y1+11,1,1);
  End;
  LastFill:=-1;
 End;
 { interligne }
 ArrowBox(WX1+375,Y1,WX1+400,Y1+10,1);
 ArrowBox(WX1+375,Y1+12,WX1+400,Y1+22,2);
 Box(WX1+401,Y1,WX1+431,Y1+22,PAPER);
 S:=IntStr(Pr.Spc Div 10)+','+IntStr(Pr.Spc Mod 10);
 PText(WX1+405,Y1+7,S);
 { cesure }
 TbBtn(WX1+465,Y1,WX1+494,Y1+22,HyphOn);
 If HyphOn Then Begin WText(WX1+470,Y1+7,'I');WText(WX1+479,Y1+7,'A');End
 Else Begin PText(WX1+470,Y1+7,'I');PText(WX1+479,Y1+7,'A');End;
 { page }
 BText(WX1+503,Y1+7,'Page');
 X:=WX1+550;
 Box(X,Y1,Min2(WX2-SBW-1,WX1+610),Y1+22,PAPER);
 Frame(X,Y1,Min2(WX2-SBW-1,WX1+610),Y1+22);
 If NPages>1 Then S:=IntStr(TopPage)+'/'+IntStr(NPages) Else S:='1';
 PText(X+4,Y1+7,S);
End;

{ ====================================================================== }
{              DESKTOP, PALETTE D'OUTILS, CORBEILLE, TOUCHES F           }
{ ====================================================================== }

Function ToolY(I: Integer): Integer;
Begin
 ToolY:=WY1+I*31;
End;

Function ToolHit(X,Y: LongInt): Integer;
Var I: Integer;
Begin
 ToolHit:=0;
 If Not ToolsOn Or FullWin Then Exit;
 For I:=1 To 6 Do
  If InBox(X,Y,0,ToolY(I),PALW-1,ToolY(I)+30) Then ToolHit:=I;
End;

Procedure DrawTool(I: Integer);
Var X1,Y1,C: Integer; Pt: Array[1..7] Of PointType;
Begin
 X1:=0;Y1:=ToolY(I);
 If Tool=I Then Begin Box(X1,Y1,X1+PALW-1,Y1+30,INK);C:=PAPER;End
 Else Begin Box(X1,Y1,X1+PALW-1,Y1+30,PAPER);Frame(X1,Y1,X1+PALW-1,Y1+30);C:=INK;End;
 SetColor(C);SetLineStyle(SolidLn,0,1);
 Case I Of
  1: Begin
    Pt[1].X:=X1+8;Pt[1].Y:=Y1+4;Pt[2].X:=X1+8;Pt[2].Y:=Y1+22;Pt[3].X:=X1+12;Pt[3].Y:=Y1+18;
    Pt[4].X:=X1+16;Pt[4].Y:=Y1+26;Pt[5].X:=X1+19;Pt[5].Y:=Y1+24;Pt[6].X:=X1+15;Pt[6].Y:=Y1+17;
    Pt[7].X:=X1+20;Pt[7].Y:=Y1+17;
    SetFillStyle(SolidFill,C);LastFill:=-1;FillPoly(7,Pt);
   End;
  2: Begin
    Line(X1+14,Y1+5,X1+14,Y1+25);Line(X1+9,Y1+5,X1+19,Y1+5);Line(X1+9,Y1+25,X1+19,Y1+25);
    Line(X1+10,Y1+7,X1+14,Y1+10);Line(X1+18,Y1+7,X1+14,Y1+10);
    Line(X1+10,Y1+23,X1+14,Y1+20);Line(X1+18,Y1+23,X1+14,Y1+20);
   End;
  3: Begin
    Line(X1+5,Y1+25,X1+14,Y1+5);Line(X1+14,Y1+5,X1+23,Y1+25);
    Line(X1+9,Y1+18,X1+19,Y1+18);Line(X1+5,Y1+25,X1+4,Y1+25);Line(X1+23,Y1+25,X1+24,Y1+25);
   End;
  4: Rectangle(X1+5,Y1+9,X1+22,Y1+21);
  5: Begin
    Frame(X1+5,Y1+9,X1+22,Y1+21);PatBar(X1+6,Y1+10,X1+21,Y1+20,PatDark);
   End;
  6: Begin
    Frame(X1+5,Y1+9,X1+22,Y1+21);PatBar(X1+6,Y1+10,X1+21,Y1+20,PatChecker);
   End;
 End;
End;

Procedure DrawPalette;
Var I: Integer;
Begin
 If Not ToolsOn Or FullWin Then Exit;
 PatBar(0,WY1,PALW-1,WY1+30,PatChecker);
 Frame(0,WY1,PALW-1,WY1+30);
 For I:=1 To 6 Do DrawTool(I);
End;

Procedure DrawTrash;
Begin
 Box(0,352,40,396,PAPER);Frame(0,352,40,396);
 Frame(10,362,30,386);Line(8,362,32,362);Line(15,358,25,358);
 Line(15,358,15,362);Line(25,358,25,362);
 Line(15,366,15,383);Line(20,366,20,383);Line(25,366,25,383);
 SmallText(5,388,'Corb.',INK);
End;

Function FKLabel(K,Row: Integer): String;
Var V: Integer;
Begin
 FKLabel:='';
 If Row=1 Then Begin
  V:=FKFont[K];
  If V>0 Then FKLabel:=FamName[(V-1) Div 8]+' '+IntStr(SizeTab[(V-1) Mod 8]);
 End Else Begin
  Case FKStyle[K] Of
   1: FKLabel:='gras';
   2: FKLabel:='soulign';
   3: FKLabel:='italique';
   4: FKLabel:='contour';
   5: FKLabel:='clair';
   6: FKLabel:='expos.';
   7: FKLabel:='indice';
   8: FKLabel:='Ligne 16';
   9: FKLabel:='nlle lig.';
   10: FKLabel:='select.';
  End;
 End;
End;

{ Le style de la touche est-il actif a la position du curseur ? }
Function StyleActive(Sty: Integer): Boolean;
Var A: Byte;
Begin
 A:=TypA;
 StyleActive:=False;
 Case Sty Of
  1: StyleActive:=(A And A_BOLD)<>0;
  2: StyleActive:=(A And A_UND)<>0;
  3: StyleActive:=(A And A_ITAL)<>0;
  4: StyleActive:=(A And A_OUT)<>0;
  5: StyleActive:=(A And A_LIGHT)<>0;
  6: StyleActive:=(A And A_SUP)<>0;
  7: StyleActive:=(A And A_SUB)<>0;
  10: StyleActive:=MarkMode;
 End;
End;

Procedure DrawFKeys;
Var K,X,Y: Integer; S: String;
Begin
 Y:=FKEY_Y+4;
 PatBar(0,FKEY_Y,SCR_W-1,SCR_H-1,PatChecker);
 Box(60,Y,SCR_W-4,Y+44,PAPER);
 Frame(60,Y,SCR_W-4,Y+44);
 PatBar(61,Y+1,67,Y+43,PatChecker);
 Frame(67,Y,67,Y+44);
 For K:=1 To 10 Do Begin
  X:=68+(K-1)*56;
  Frame(X,Y,X+56,Y+44);
  Frame(X+8,Y+3,X+48,Y+14);
  S:='F'+IntStr(K);
  SmallText(X+28-Length(S)*3,Y+5,S,INK);
  Line(X,Y+17,X+56,Y+17);
  Line(X,Y+30,X+56,Y+30);
  S:=FKLabel(K,1);
  If S<>'' Then SmallText(X+28-Length(S)*3,Y+21,S,INK);
  S:=FKLabel(K,2);
  If StyleActive(FKStyle[K]) And (FKStyle[K]>0) Then Begin
   Box(X+1,Y+31,X+55,Y+43,INK);
   If S<>'' Then SmallText(X+28-Length(S)*3,Y+34,S,PAPER);
  End Else If S<>'' Then SmallText(X+28-Length(S)*3,Y+34,S,INK);
 End;
End;

Function FKeyHit(X,Y: LongInt; Var Row: Integer): Integer;
Begin
 FKeyHit:=0;Row:=0;
 If (Y<FKEY_Y+4) Or (Y>FKEY_Y+48) Or (X<68) Or (X>=68+560) Then Exit;
 If Y<FKEY_Y+21 Then Row:=0 Else If Y<FKEY_Y+34 Then Row:=1 Else Row:=2;
 FKeyHit:=(X-68) Div 56+1;
End;

Procedure DrawWindow;
Var Y2: Integer;
Begin
 CalcGeo;
 DrawTitleBar;
 Box(WX1,WY1+TBH+1,WX2,WY2,PAPER);
 Frame(WX1,WY1,WX2,WY2);
 DrawRuler;
 DrawToolbar;
 ClampScroll;
 DrawDoc;
 { barres de defilement }
 DrawScrollV(WX2-SBW+1,WY1+TBH+1,WX2,WY2-SBW,ScrY,MaxScrY);
 DrawScrollH(WX1+1,WY2-SBW+1,WX2-SBW,WY2-1,ScrX,MaxScrX);
 Box(WX2-SBW+1,WY2-SBW+1,WX2-1,WY2-1,PAPER);
 Frame(WX2-SBW+1,WY2-SBW+1,WX2,WY2);
 Line(WX2-SBW+5,WY2-4,WX2-4,WY2-SBW+5);
End;

Procedure DrawAll;
Var Pg: Integer;
Begin
 HideMouse;
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 LastFill:=-1;
 PatBar(0,MENU_H,SCR_W-1,FKEY_Y-1,PatChecker);
 DrawTrash;
 DrawPalette;
 CurPg:=CurPg;
 DrawWindow;
 DrawFKeys;
 DrawMenuBar;
 DrawDropDown;
 ShowMouse;
 NeedDraw:=False;
 CaretT:=Tick;
End;

{ ====================================================================== }
{                  DOCUMENT : INITIALISATION ET FORMATS                  }
{ ====================================================================== }

Type
 TCfg = Record
  Fmt,L,R,T,B,Hd,Ft,Nc,Gp,Ps,Hf: Integer;
  Mir,Hy: Boolean;
  Lang: Integer;
  F1,F2,F3,F4,F5: Integer;
 End;

Var
 Snap      : TCfg;
 FindStr,ReplStr : String[40];
 FindCase  : Boolean;
 PrintDest : String[60];
 DefDir    : String[60];

Procedure SetPageFormat(F: Integer);
Begin
 PgFmt:=F;
 Case F Of
  0: Begin PgW:=2100;PgH:=2970;End;
  1: Begin PgW:=1480;PgH:=2100;End;
  2: Begin PgW:=2970;PgH:=4200;End;
  3: Begin PgW:=2159;PgH:=2794;End;
  Else Begin PgW:=2100;PgH:=2970;End;
 End;
End;

Procedure SaveSnap;
Begin
 Snap.Fmt:=PgFmt;Snap.L:=MarL;Snap.R:=MarR;Snap.T:=MarT;Snap.B:=MarB;
 Snap.Hd:=HeadH;Snap.Ft:=FootH;Snap.Nc:=NCols;Snap.Gp:=ColGap;
 Snap.Ps:=PgStart;Snap.Hf:=HFFrom;Snap.Mir:=Mirror;Snap.Hy:=HyphOn;Snap.Lang:=HyphLang;
 Snap.F1:=FnA;Snap.F2:=FnB;Snap.F3:=FnC;Snap.F4:=FnD;Snap.F5:=FnE;
End;

Procedure RestoreSnap;
Begin
 SetPageFormat(Snap.Fmt);MarL:=Snap.L;MarR:=Snap.R;MarT:=Snap.T;MarB:=Snap.B;
 HeadH:=Snap.Hd;FootH:=Snap.Ft;NCols:=Snap.Nc;ColGap:=Snap.Gp;
 PgStart:=Snap.Ps;HFFrom:=Snap.Hf;Mirror:=Snap.Mir;HyphOn:=Snap.Hy;HyphLang:=Snap.Lang;
 FnA:=Snap.F1;FnB:=Snap.F2;FnC:=Snap.F3;FnD:=Snap.F4;FnE:=Snap.F5;
 Relayout;
End;

Procedure DefaultConfig;
Begin
 SetPageFormat(0);
 MarL:=20;MarR:=20;MarT:=10;MarB:=10;HeadH:=15;FootH:=15;NCols:=1;ColGap:=10;
 Mirror:=False;PgStart:=1;HFFrom:=1;
 FnA:=0;FnB:=0;FnC:=0;FnD:=0;FnE:=0;
 HyphOn:=True;HyphLang:=2;
End;

Procedure DefaultFmts;
Begin
 NFmt:=2;
 Fmts[1].Name:='Paragraphe 8pt';Fmts[1].Fam:=0;Fmts[1].Sz:=1;Fmts[1].At:=0;
 Fmts[1].Al:=1;Fmts[1].Spc:=14;
 Fmts[2].Name:='Titre 10pt';Fmts[2].Fam:=1;Fmts[2].Sz:=2;Fmts[2].At:=A_BOLD;
 Fmts[2].Al:=2;Fmts[2].Spc:=16;
End;

Procedure DefaultFKeys;
Var K: Integer;
Begin
 For K:=1 To 10 Do Begin FKFont[K]:=0;FKStyle[K]:=0;End;
 FKStyle[1]:=1;
 FKFont[2]:=2;FKStyle[2]:=2;
 FKFont[3]:=3;FKStyle[3]:=3;
 FKFont[4]:=4;FKStyle[4]:=4;
 FKStyle[5]:=5;FKStyle[6]:=6;
 FKFont[7]:=10;FKStyle[7]:=7;
 FKFont[8]:=11;FKStyle[8]:=8;
 FKStyle[9]:=10;FKStyle[10]:=9;
End;

Procedure FreeObjects;
Var I: Integer;
Begin
 For I:=1 To NObj Do Begin
  If Obj[I].Img<>Nil Then FreeMem(Obj[I].Img,((Obj[I].IW+7) Div 8)*Obj[I].IH);
  Obj[I].Img:=Nil;
 End;
 For I:=3 To NSTORY-1 Do FreeStory(I);
 NObj:=0;
End;

Procedure NewDoc;
Var I: Integer;
Begin
 FreeObjects;
 For I:=0 To 2 Do ClearStory(I);
 ASt:=0;Cur:=0;SelA:=-1;SelObj:=0;TypA:=0;TypF:=DEFF;
 ScrX:=0;ScrY:=0;CurPg:=1;DocName:='';Named:=False;Modified:=False;
 UndoOK:=False;LastTyping:=False;WantX:=-1;
 Relayout;
End;

{ ====================================================================== }
{                       EDITION DU TEXTE                                 }
{ ====================================================================== }

Function SelRange(Var A,B: Integer): Boolean;
Begin
 SelRange:=False;
 If (SelA<0) Or (SelA=Cur) Then Exit;
 If SelA<Cur Then Begin A:=SelA;B:=Cur;End Else Begin A:=Cur;B:=SelA;End;
 SelRange:=True;
End;

Procedure SyncTyp;
Begin
 With St[ASt] Do Begin
  If Cur>0 Then Begin
   If (T^[Cur-1]=13) And (Cur<Len) Then Begin TypA:=A^[Cur];TypF:=F^[Cur];End
   Else Begin TypA:=A^[Cur-1];TypF:=F^[Cur-1];End;
  End Else If Len>0 Then Begin TypA:=A^[0];TypF:=F^[0];End;
 End;
End;

Procedure BeginEdit(Typing: Boolean);
Begin
 If Not (Typing And LastTyping) Then PushUndo;
 LastTyping:=Typing;
 Modified:=True;
End;

Procedure ScrollToCaret;
Var Pg: Integer; Xd,Yd,Hd,Y,X: LongInt; Ok: Boolean;
Begin
 CalcGeo;
 CaretGeom(Pg,Xd,Yd,Hd,Ok);
 If Not Ok Then Exit;
 If ASt=0 Then CurPg:=Pg;
 Y:=4+LongInt(Pg-1)*StridePx+D2P(Yd);
 If Y<ScrY Then ScrY:=Y-8
 Else If Y+D2P(Hd)>ScrY+(VY2-VY1) Then ScrY:=Y+D2P(Hd)-(VY2-VY1)+8;
 X:=6+D2P(Xd);
 If X<ScrX+4 Then ScrX:=X-30
 Else If X>ScrX+(VX2-VX1)-4 Then ScrX:=X-(VX2-VX1)+30;
 ClampScroll;
End;

Procedure MoveTo(NewPos: Integer; Extend: Boolean);
Begin
 If NewPos<0 Then NewPos:=0;
 If NewPos>St[ASt].Len Then NewPos:=St[ASt].Len;
 If Extend Or MarkMode Then Begin
  If SelA<0 Then SelA:=Cur;
 End Else SelA:=-1;
 Cur:=NewPos;
 LastTyping:=False;
 SyncTyp;
 ScrollToCaret;
 NeedDraw:=True;
End;

Function DelSel: Boolean;
Var A,B: Integer;
Begin
 DelSel:=False;
 If SelRange(A,B) Then Begin
  StDel(ASt,A,B);Cur:=A;SelA:=-1;Relayout;DelSel:=True;
 End;
End;

Procedure InsChar(Ch: Byte);
Begin
 BeginEdit(True);
 DelSel;
 If StIns(ASt,Cur,Ch,TypA,TypF) Then Inc(Cur);
 SelA:=-1;WantX:=-1;
 Relayout;
 ScrollToCaret;
 NeedDraw:=True;
End;

Procedure DoBackspace;
Begin
 BeginEdit(False);
 If Not DelSel Then
  If Cur>0 Then Begin StDel(ASt,Cur-1,Cur);Dec(Cur);Relayout;End;
 WantX:=-1;SyncTyp;ScrollToCaret;NeedDraw:=True;
End;

Procedure DoDelete;
Begin
 BeginEdit(False);
 If Not DelSel Then
  If Cur<St[ASt].Len Then Begin StDel(ASt,Cur,Cur+1);Relayout;End;
 WantX:=-1;SyncTyp;ScrollToCaret;NeedDraw:=True;
End;

Procedure CurUpDown(Dir: Integer; Extend: Boolean);
Var L: PLineArr; N,I,J: Integer;
Begin
 GetLines(ASt,L,N);
 If N=0 Then Exit;
 I:=LineOfPos(L,N,Cur);
 If WantX<0 Then WantX:=XOfPos(ASt,L,I,Cur);
 J:=I+Dir;
 If J<0 Then Begin MoveTo(0,Extend);Exit;End;
 If J>=N Then Begin MoveTo(St[ASt].Len,Extend);Exit;End;
 Dir:=PosAtX(ASt,L,J,WantX);
 MoveTo(Dir,Extend);
End;

Procedure CurLineEdge(Home,Extend: Boolean);
Var L: PLineArr; N,I: Integer;
Begin
 GetLines(ASt,L,N);
 If N=0 Then Exit;
 I:=LineOfPos(L,N,Cur);
 If Home Then MoveTo(L^[I].S,Extend) Else MoveTo(L^[I].E,Extend);
 WantX:=-1;
End;

Procedure CurWord(Dir: Integer; Extend: Boolean);
Var P: Integer;
Begin
 P:=Cur;
 With St[ASt] Do Begin
  If Dir>0 Then Begin
   While (P<Len) And IsLetter(T^[P]) Do Inc(P);
   While (P<Len) And Not IsLetter(T^[P]) Do Inc(P);
  End Else Begin
   While (P>0) And Not IsLetter(T^[P-1]) Do Dec(P);
   While (P>0) And IsLetter(T^[P-1]) Do Dec(P);
  End;
 End;
 MoveTo(P,Extend);WantX:=-1;
End;

{ ---- styles ---- }
Procedure ForSel(Var A,B: Integer);
Begin
 If Not SelRange(A,B) Then Begin A:=0;B:=0;End;
End;

Procedure ToggleStyle(Bit: Byte);
Var A,B,I: Integer; All: Boolean;
Begin
 BeginEdit(False);
 ForSel(A,B);
 If B>A Then Begin
  All:=True;
  For I:=A To B-1 Do If (St[ASt].A^[I] And Bit)=0 Then All:=False;
  For I:=A To B-1 Do
   If All Then St[ASt].A^[I]:=St[ASt].A^[I] And Not Bit
   Else Begin
    St[ASt].A^[I]:=St[ASt].A^[I] Or Bit;
    If Bit=A_SUP Then St[ASt].A^[I]:=St[ASt].A^[I] And Not A_SUB;
    If Bit=A_SUB Then St[ASt].A^[I]:=St[ASt].A^[I] And Not A_SUP;
   End;
 End Else Begin
  If (TypA And Bit)<>0 Then TypA:=TypA And Not Bit
  Else Begin
   TypA:=TypA Or Bit;
   If Bit=A_SUP Then TypA:=TypA And Not A_SUB;
   If Bit=A_SUB Then TypA:=TypA And Not A_SUP;
  End;
 End;
 Relayout;NeedDraw:=True;
End;

Procedure PlainStyle;
Var A,B,I: Integer;
Begin
 BeginEdit(False);
 ForSel(A,B);
 If B>A Then For I:=A To B-1 Do St[ASt].A^[I]:=0 Else TypA:=0;
 Relayout;NeedDraw:=True;
End;

Procedure SetFont(Fam,Sz: Integer);
Var A,B,I: Integer;
Begin
 BeginEdit(False);
 ForSel(A,B);
 If B>A Then Begin
  For I:=A To B-1 Do St[ASt].F^[I]:=(St[ASt].F^[I] And $F0) Or Sz Or (Fam Shl 3);
 End Else TypF:=(TypF And $F0) Or Sz Or (Fam Shl 3);
 Relayout;NeedDraw:=True;
End;

Procedure SetColorIdx(C: Integer);
Var A,B,I: Integer;
Begin
 BeginEdit(False);
 ForSel(A,B);
 If B>A Then Begin
  For I:=A To B-1 Do St[ASt].F^[I]:=(St[ASt].F^[I] And $0F) Or (C Shl 4);
 End Else TypF:=(TypF And $0F) Or (C Shl 4);
 Relayout;NeedDraw:=True;
End;

Procedure ParaRange(Var P1,P2: Integer);
Var A,B: Integer;
Begin
 If SelRange(A,B) Then Begin P1:=ParaOf(ASt,A);P2:=ParaOf(ASt,B);End
 Else Begin P1:=ParaOf(ASt,Cur);P2:=P1;End;
End;

Procedure SetAlign(Al: Integer);
Var P1,P2,I: Integer;
Begin
 BeginEdit(False);
 ParaRange(P1,P2);
 For I:=P1 To P2 Do Begin St[ASt].Pa^[I].Al:=Al;St[ASt].Pa^[I].Fm:=0;End;
 Relayout;NeedDraw:=True;
End;

Procedure SetSpacing(V: Integer);
Var P1,P2,I: Integer;
Begin
 If V<8 Then V:=8;
 If V>40 Then V:=40;
 BeginEdit(False);
 ParaRange(P1,P2);
 For I:=P1 To P2 Do St[ASt].Pa^[I].Spc:=V;
 Relayout;NeedDraw:=True;
End;

Procedure ApplyFormat(Idx: Integer);
Var P1,P2,I,Ps,Pe,K: Integer;
Begin
 BeginEdit(False);
 ParaRange(P1,P2);
 For I:=P1 To P2 Do Begin
  St[ASt].Pa^[I].Fm:=Idx;
  If Idx>0 Then Begin
   St[ASt].Pa^[I].Al:=Fmts[Idx].Al;
   St[ASt].Pa^[I].Spc:=Fmts[Idx].Spc;
   Ps:=ParaStart(ASt,I);Pe:=ParaEndOf(ASt,Ps);
   If Pe<St[ASt].Len Then Inc(Pe);
   For K:=Ps To Pe-1 Do Begin
    St[ASt].F^[K]:=(St[ASt].F^[K] And $F0) Or Fmts[Idx].Sz Or (Fmts[Idx].Fam Shl 3);
    St[ASt].A^[K]:=Fmts[Idx].At;
   End;
  End;
 End;
 SyncTyp;
 Relayout;NeedDraw:=True;
End;

Procedure SetTab(Pos_: Integer; Kind: Byte);
Var Pn,I: Integer;
Begin
 BeginEdit(False);
 Pn:=ParaOf(ASt,Cur);
 With St[ASt].Pa^[Pn] Do Begin
  { un taquet proche est supprime }
  For I:=1 To NT Do
   If Abs(Tb[I].P-Pos_)<25 Then Begin
    Tb[I]:=Tb[NT];Dec(NT);Relayout;NeedDraw:=True;Exit;
   End;
  If NT<6 Then Begin Inc(NT);Tb[NT].P:=Pos_;Tb[NT].K:=Kind;End;
 End;
 Relayout;NeedDraw:=True;
End;

{ ---- presse-papiers ---- }
Procedure ClipCopy;
Var A,B: Integer;
Begin
 If Not SelRange(A,B) Then Exit;
 If B-A>CLIPCAP Then B:=A+CLIPCAP;
 If ClipT=Nil Then Begin GetMem(ClipT,CLIPCAP);GetMem(ClipA,CLIPCAP);GetMem(ClipF,CLIPCAP);End;
 Move(St[ASt].T^[A],ClipT^,B-A);
 Move(St[ASt].A^[A],ClipA^,B-A);
 Move(St[ASt].F^[A],ClipF^,B-A);
 ClipN:=B-A;
End;

Procedure ClipCut;
Begin
 ClipCopy;
 BeginEdit(False);
 DelSel;
 WantX:=-1;SyncTyp;ScrollToCaret;NeedDraw:=True;
End;

Procedure ClipPaste;
Var I: Integer;
Begin
 If ClipN=0 Then Exit;
 BeginEdit(False);
 DelSel;
 For I:=0 To ClipN-1 Do
  If StIns(ASt,Cur,ClipT^[I],ClipA^[I],ClipF^[I]) Then Inc(Cur);
 SelA:=-1;WantX:=-1;
 Relayout;ScrollToCaret;NeedDraw:=True;
End;

Procedure SelectAll;
Begin
 SelA:=0;Cur:=St[ASt].Len;NeedDraw:=True;
End;

Procedure DoUndo;
Var S: Integer;
Begin
 If Not UndoOK Then Exit;
 S:=UndoSt;ASt:=S;
 If UndoLen>St[S].Cap Then Exit;
 St[S].Len:=UndoLen;
 Move(UndoT^,St[S].T^,UndoLen);
 Move(UndoA^,St[S].A^,UndoLen);
 Move(UndoF^,St[S].F^,UndoLen);
 St[S].NP:=UndoNP;
 Move(UndoPa^,St[S].Pa^,UndoNP*SizeOf(TPara));
 Cur:=UndoCur;SelA:=-1;UndoOK:=False;LastTyping:=False;
 Relayout;SyncTyp;ScrollToCaret;NeedDraw:=True;
End;

{ ---- recherche ---- }
Function MatchAt(Ps: Integer; Const Pat: String): Boolean;
Var I: Integer; A,B: Byte;
Begin
 MatchAt:=False;
 If Ps+Length(Pat)>St[ASt].Len Then Exit;
 For I:=1 To Length(Pat) Do Begin
  A:=St[ASt].T^[Ps+I-1];B:=Ord(Pat[I]);
  If Not FindCase Then Begin A:=LoCase(A);B:=LoCase(B);End;
  If A<>B Then Exit;
 End;
 MatchAt:=True;
End;

Function FindText(Wrap: Boolean): Boolean;
Var I,Start,N: Integer;
Begin
 FindText:=False;
 If FindStr='' Then Exit;
 N:=St[ASt].Len;
 Start:=Cur;
 If (SelA>=0) And (SelA<Cur) Then Start:=Cur;
 If (SelA>=0) And (SelA>Cur) Then Start:=SelA;
 For I:=0 To N-1 Do Begin
  If (Not Wrap) And (Start+I>N) Then Exit;
  If MatchAt((Start+I) Mod (N+1),FindStr) Then Begin
   SelA:=(Start+I) Mod (N+1);Cur:=SelA+Length(FindStr);
   LastTyping:=False;
   ScrollToCaret;NeedDraw:=True;
   FindText:=True;Exit;
  End;
 End;
End;

{ ====================================================================== }
{                              OBJETS                                    }
{ ====================================================================== }

Function NewObject(AKind: Byte; Pg,X,Y,W,H: Integer): Integer;
Var I,S: Integer;
Begin
 NewObject:=0;
 If NObj>=MAXOBJ Then Exit;
 S:=0;
 If AKind=OB_TEXT Then Begin
  For I:=3 To NSTORY-1 Do If Not St[I].Used Then Begin S:=I;Break;End;
  If S=0 Then Exit;
  AllocStory(S,FRCAP,FRPAR);
 End;
 Inc(NObj);
 FillChar(Obj[NObj],SizeOf(TObj),0);
 Obj[NObj].Kind:=AKind;Obj[NObj].Pg:=Pg;
 Obj[NObj].X:=X;Obj[NObj].Y:=Y;Obj[NObj].W:=W;Obj[NObj].H:=H;
 Obj[NObj].St:=S;Obj[NObj].Col:=1;
 Case AKind Of
  OB_TEXT: Obj[NObj].Bord:=1;
  OB_RECT: Obj[NObj].Bord:=1;
  OB_LINE: Obj[NObj].Bord:=2;
 End;
 NewObject:=NObj;
 Modified:=True;
End;

Procedure DeleteObject(I: Integer);
Var K: Integer;
Begin
 If (I<1) Or (I>NObj) Then Exit;
 If Obj[I].Kind=OB_TEXT Then Begin
  If ASt=Obj[I].St Then Begin ASt:=0;Cur:=0;SelA:=-1;End;
  FreeStory(Obj[I].St);
 End;
 If Obj[I].Img<>Nil Then FreeMem(Obj[I].Img,((Obj[I].IW+7) Div 8)*Obj[I].IH);
 For K:=I To NObj-1 Do Obj[K]:=Obj[K+1];
 Dec(NObj);
 SelObj:=0;Modified:=True;Relayout;NeedDraw:=True;
End;

Procedure ObjToFront;
Var T: TObj; K: Integer;
Begin
 If SelObj=0 Then Exit;
 T:=Obj[SelObj];
 For K:=SelObj To NObj-1 Do Obj[K]:=Obj[K+1];
 Obj[NObj]:=T;SelObj:=NObj;NeedDraw:=True;
End;

Procedure ObjToBack;
Var T: TObj; K: Integer;
Begin
 If SelObj=0 Then Exit;
 T:=Obj[SelObj];
 For K:=SelObj Downto 2 Do Obj[K]:=Obj[K-1];
 Obj[1]:=T;SelObj:=1;NeedDraw:=True;
End;

{ Image PBM (P4) : bitmap noir et blanc }
Function LoadPBM(Const Name: String; O: Integer): Boolean;
Var F: File; Buf: Array[0..127] Of Byte; N,P,Cnt: Integer; W,H: LongInt; Sz: LongInt;
 Function NextNum: LongInt;
 Var V: LongInt;
 Begin
  V:=0;
  While (P<N) And ((Buf[P]<48) Or (Buf[P]>57)) Do Begin
   If Buf[P]=35 Then While (P<N) And (Buf[P]<>10) Do Inc(P);
   Inc(P);
  End;
  While (P<N) And (Buf[P]>=48) And (Buf[P]<=57) Do Begin V:=V*10+Buf[P]-48;Inc(P);End;
  NextNum:=V;
 End;
Begin
 LoadPBM:=False;
 {$I-}
 Assign(F,Name);Reset(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 BlockRead(F,Buf,128,N);
 If (N<10) Or (Buf[0]<>80) Or (Buf[1]<>52) Then Begin Close(F);Exit;End;
 P:=2;W:=NextNum;H:=NextNum;Inc(P);
 Sz:=((W+7) Div 8)*H;
 If (W<1) Or (H<1) Or (Sz>60000) Then Begin Close(F);Exit;End;
 Seek(F,P);
 If Obj[O].Img<>Nil Then FreeMem(Obj[O].Img,((Obj[O].IW+7) Div 8)*Obj[O].IH);
 GetMem(Obj[O].Img,Sz);
 BlockRead(F,Obj[O].Img^,Sz,Cnt);
 Close(F);
 Obj[O].IW:=W;Obj[O].IH:=H;
 LoadPBM:=True;
End;

{ Petit logo fabrique en memoire (roseaux de papyrus) }
Procedure BmpPlot(O,X,Y: Integer);
Var Bw: Integer;
Begin
 If (X<0) Or (Y<0) Or (X>=Obj[O].IW) Or (Y>=Obj[O].IH) Then Exit;
 Bw:=(Obj[O].IW+7) Div 8;
 Obj[O].Img^[Y*Bw+X Shr 3]:=Obj[O].Img^[Y*Bw+X Shr 3] Or ($80 Shr (X And 7));
End;

Procedure BmpLine(O,X1,Y1,X2,Y2: Integer);
Var N,I: Integer;
Begin
 N:=Abs(X2-X1);If Abs(Y2-Y1)>N Then N:=Abs(Y2-Y1);
 If N=0 Then N:=1;
 For I:=0 To N Do BmpPlot(O,X1+(X2-X1)*I Div N,Y1+(Y2-Y1)*I Div N);
End;

Procedure BmpEll(O,CX,CY,RX,RY: Integer);
Var A: Integer;
Begin
 For A:=0 To 359 Do
  BmpPlot(O,CX+Round(RX*Cos(A*Pi/180)),CY+Round(RY*Sin(A*Pi/180)));
End;

Procedure MakeLogo(O: Integer);
Var Sz: LongInt; I,J,X: Integer; Cp: Array[0..4] Of Integer;
Begin
 Obj[O].IW:=160;Obj[O].IH:=100;
 Sz:=20*100;
 GetMem(Obj[O].Img,Sz);
 FillChar(Obj[O].Img^,Sz,0);
 { roseaux }
 For I:=0 To 4 Do Begin
  X:=40+I*20;
  BmpLine(O,X,80,X+(I-2)*5,26+Abs(I-2)*6);
  BmpLine(O,X+1,80,X+1+(I-2)*5,26+Abs(I-2)*6);
  For J:=0 To 4 Do BmpEll(O,X+(I-2)*5,24+Abs(I-2)*6,3+J Div 3,9-J);
 End;
 { eau }
 For I:=0 To 5 Do BmpLine(O,10+I*3,82+I*3,150-I*3,82+I*3);
 { signature }
 For I:=0 To 3 Do BmpLine(O,20,60+I,140,50+I);
End;

{ ====================================================================== }
{                              FICHIERS                                  }
{ ====================================================================== }

Var
 FW : File;
 FOk: Boolean;

Procedure WB(V: Integer);
Var B: Byte;
Begin
 B:=V And $FF;
 BlockWrite(FW,B,1);
End;

Procedure WI(V: Integer);
Begin
 WB(V And $FF);WB((V Shr 8) And $FF);
End;

Function RB: Integer;
Var B: Byte; N: Integer;
Begin
 BlockRead(FW,B,1,N);
 If N<>1 Then Begin FOk:=False;B:=0;End;
 RB:=B;
End;

Function RI: Integer;
Var A,B: Integer;
Begin
 A:=RB;B:=RB;
 RI:=Integer(A Or (B Shl 8));
End;

Function SavePAP(Const Name: String): Boolean;
Var S,I,K,N: Integer;
Begin
 SavePAP:=False;
 {$I-}
 Assign(FW,Name);Rewrite(FW,1);
 {$I+}
 If IOResult<>0 Then Exit;
 WB(80);WB(65);WB(80);WB(49);
 WI(PgFmt);WI(MarL);WI(MarR);WI(MarT);WI(MarB);WI(HeadH);WI(FootH);
 WI(NCols);WI(ColGap);WI(PgStart);WI(HFFrom);WI(Ord(Mirror));WI(Ord(HyphOn));
 WI(HyphLang);WI(FnA);WI(FnB);WI(FnC);WI(FnD);WI(FnE);
 WI(NFmt);
 For I:=1 To NFmt Do Begin
  BlockWrite(FW,Fmts[I].Name,19);
  WB(Fmts[I].Fam);WB(Fmts[I].Sz);WB(Fmts[I].At);WB(Fmts[I].Al);WB(Fmts[I].Spc);
 End;
 N:=0;
 For S:=0 To NSTORY-1 Do If St[S].Used Then Inc(N);
 WI(N);
 For S:=0 To NSTORY-1 Do If St[S].Used Then Begin
  WI(S);WI(St[S].Len);WI(St[S].NP);
  If St[S].Len>0 Then Begin
   BlockWrite(FW,St[S].T^,St[S].Len);
   BlockWrite(FW,St[S].A^,St[S].Len);
   BlockWrite(FW,St[S].F^,St[S].Len);
  End;
  For I:=0 To St[S].NP-1 Do With St[S].Pa^[I] Do Begin
   WB(Al);WB(Spc);WB(Fm);WB(NT);WI(LI);WI(FI);WI(SA);
   For K:=1 To 6 Do Begin WI(Tb[K].P);WB(Tb[K].K);End;
  End;
 End;
 WI(NObj);
 For I:=1 To NObj Do Begin
  WB(Obj[I].Kind);WB(Obj[I].Fill);WB(Obj[I].Bord);WB(Obj[I].Ang);WB(Obj[I].Col);
  WI(Obj[I].Pg);WI(Obj[I].X);WI(Obj[I].Y);WI(Obj[I].W);WI(Obj[I].H);WI(Obj[I].St);
  WI(Obj[I].IW);WI(Obj[I].IH);
  If Obj[I].Img<>Nil Then BlockWrite(FW,Obj[I].Img^,((Obj[I].IW+7) Div 8)*Obj[I].IH);
 End;
 Close(FW);
 SavePAP:=IOResult=0;
End;

Function LoadPAP(Const Name: String): Boolean;
Var S,I,K,N,Cnt,M0,M1,M2,M3: Integer; Sz: LongInt; Ln,Np: Integer;
Begin
 LoadPAP:=False;
 {$I-}
 Assign(FW,Name);Reset(FW,1);
 {$I+}
 If IOResult<>0 Then Exit;
 FOk:=True;
 M0:=RB;M1:=RB;M2:=RB;M3:=RB;
 If (M0<>80) Or (M1<>65) Or (M2<>80) Or (M3<>49) Then Begin Close(FW);Exit;End;
 NewDoc;
 PgFmt:=RI;MarL:=RI;MarR:=RI;MarT:=RI;MarB:=RI;HeadH:=RI;FootH:=RI;
 NCols:=RI;ColGap:=RI;PgStart:=RI;HFFrom:=RI;Mirror:=RI<>0;HyphOn:=RI<>0;
 HyphLang:=RI;FnA:=RI;FnB:=RI;FnC:=RI;FnD:=RI;FnE:=RI;
 SetPageFormat(PgFmt);
 If (NCols<1) Or (NCols>4) Then NCols:=1;
 NFmt:=RI;
 If (NFmt<0) Or (NFmt>MAXFMT) Then NFmt:=0;
 For I:=1 To NFmt Do Begin
  BlockRead(FW,Fmts[I].Name,19,Cnt);
  Fmts[I].Fam:=RB;Fmts[I].Sz:=RB;Fmts[I].At:=RB;Fmts[I].Al:=RB;Fmts[I].Spc:=RB;
 End;
 N:=RI;
 For K:=1 To N Do Begin
  S:=RI;Ln:=RI;Np:=RI;
  If (S<0) Or (S>=NSTORY) Or Not FOk Then Begin FOk:=False;Break;End;
  If Not St[S].Used Then Begin
   If S<=2 Then AllocStory(S,HFCAP,HFPAR) Else AllocStory(S,FRCAP,FRPAR);
  End;
  If (Ln>St[S].Cap) Or (Np>St[S].MaxP) Or (Np<1) Then Begin FOk:=False;Break;End;
  St[S].Len:=Ln;St[S].NP:=Np;
  If Ln>0 Then Begin
   BlockRead(FW,St[S].T^,Ln,Cnt);
   BlockRead(FW,St[S].A^,Ln,Cnt);
   BlockRead(FW,St[S].F^,Ln,Cnt);
  End;
  For I:=0 To Np-1 Do With St[S].Pa^[I] Do Begin
   Al:=RB;Spc:=RB;Fm:=RB;NT:=RB;LI:=RI;FI:=RI;SA:=RI;
   For M0:=1 To 6 Do Begin Tb[M0].P:=RI;Tb[M0].K:=RB;End;
  End;
 End;
 If FOk Then Begin
  NObj:=RI;
  If (NObj<0) Or (NObj>MAXOBJ) Then Begin NObj:=0;FOk:=False;End;
  For I:=1 To NObj Do Begin
   Obj[I].Kind:=RB;Obj[I].Fill:=RB;Obj[I].Bord:=RB;Obj[I].Ang:=RB;Obj[I].Col:=RB;
   Obj[I].Pg:=RI;Obj[I].X:=RI;Obj[I].Y:=RI;Obj[I].W:=RI;Obj[I].H:=RI;Obj[I].St:=RI;
   Obj[I].IW:=RI;Obj[I].IH:=RI;Obj[I].Img:=Nil;
   If (Obj[I].IW>0) And (Obj[I].IH>0) Then Begin
    Sz:=((Obj[I].IW+7) Div 8)*Obj[I].IH;
    If Sz<=60000 Then Begin
     GetMem(Obj[I].Img,Sz);
     BlockRead(FW,Obj[I].Img^,Sz,Cnt);
    End Else FOk:=False;
   End;
  End;
 End;
 Close(FW);
 DocName:=Name;Named:=True;Modified:=False;
 LoadPAP:=FOk;
 Relayout;
End;

Function ImportASCII(Const Name: String): Boolean;
Var F: Text; L: String; I: Integer; First: Boolean;
Begin
 ImportASCII:=False;
 {$I-}
 Assign(F,Name);Reset(F);
 {$I+}
 If IOResult<>0 Then Exit;
 PushUndo;
 First:=True;
 While Not Eof(F) Do Begin
  ReadLn(F,L);
  If Not First Then StIns(ASt,St[ASt].Len,13,TypA,TypF);
  First:=False;
  For I:=1 To Length(L) Do
   If L[I]=#9 Then StIns(ASt,St[ASt].Len,9,TypA,TypF)
   Else If L[I]>=' ' Then StIns(ASt,St[ASt].Len,Ord(L[I]),TypA,TypF);
 End;
 Close(F);
 Relayout;Modified:=True;
 ImportASCII:=True;
End;

Function ExportASCII(Const Name: String): Boolean;
Var Fo: Text; I: Integer; C: Byte;
Begin
 ExportASCII:=False;
 {$I-}
 Assign(Fo,Name);Rewrite(Fo);
 {$I+}
 If IOResult<>0 Then Exit;
 With St[0] Do
  For I:=0 To Len-1 Do Begin
   C:=T^[I];
   If C=13 Then WriteLn(Fo)
   Else If C=10 Then WriteLn(Fo)
   Else If C=12 Then Write(Fo,#12)
   Else If C<>1 Then Write(Fo,Chr(C));
  End;
 WriteLn(Fo);
 Close(Fo);
 ExportASCII:=True;
End;

{ ---- configuration ---- }
Procedure SaveConfig;
Var K: Integer;
Begin
 {$I-}
 Assign(FW,'PAPYRUS.CFG');Rewrite(FW,1);
 {$I+}
 If IOResult<>0 Then Exit;
 WI(Ord(ToolsOn));WI(Ord(RulerOn));WI(Ord(FormatOn));WI(Ord(GuidesOn));
 WI(Zoom);WI(Ord(HyphOn));WI(HyphLang);
 For K:=1 To 10 Do Begin WB(FKFont[K]);WB(FKStyle[K]);End;
 Close(FW);
End;

Procedure LoadConfig;
Var K: Integer;
Begin
 FOk:=True;
 {$I-}
 Assign(FW,'PAPYRUS.CFG');Reset(FW,1);
 {$I+}
 If IOResult<>0 Then Exit;
 ToolsOn:=RI<>0;RulerOn:=RI<>0;FormatOn:=RI<>0;GuidesOn:=RI<>0;
 Zoom:=RI;HyphOn:=RI<>0;HyphLang:=RI;
 For K:=1 To 10 Do Begin FKFont[K]:=RB;FKStyle[K]:=RB;End;
 Close(FW);
 If (Zoom<25) Or (Zoom>300) Then Zoom:=100;
 If (HyphLang<1) Or (HyphLang>6) Then HyphLang:=2;
 If Not FOk Then DefaultFKeys;
End;

{ ====================================================================== }
{                              IMPRESSION                                }
{ ====================================================================== }

Function LineText(S: Integer; L: PLineArr; I: Integer): String;
Var K: Integer; R: String; C: Byte;
Begin
 R:='';
 For K:=L^[I].S To L^[I].E-1 Do Begin
  C:=St[S].T^[K];
  If C=9 Then R:=R+'    '
  Else If C=1 Then R:=R+IntStr(PgStart)
  Else If C>=32 Then R:=R+Chr(C);
 End;
 If (L^[I].Fl And 1)<>0 Then R:=R+'-';
 LineText:=R;
End;

Function AlignText(Const S: String; Al,W: Integer): String;
Var P: Integer; R: String;
Begin
 R:=S;
 If Al=2 Then P:=(W-Length(R)) Div 2 Else If Al=3 Then P:=W-Length(R) Else P:=0;
 While P>0 Do Begin R:=' '+R;Dec(P);End;
 AlignText:=R;
End;

Function PrintPages(P1,P2: Integer): Boolean;
Var F: Text; I,P,Pg: Integer; Dest: String; Lt: PLineArr; Nt: Integer; S: String;
 Started: Boolean;
Begin
 PrintPages:=False;
 EnsureLayout;
 Dest:=PrintDest;
 {$I-}
 Assign(F,Dest);Rewrite(F);
 If IOResult<>0 Then Begin
  Dest:='PAPYRUS.PRN';
  Assign(F,Dest);Rewrite(F);
 End;
 {$I+}
 If IOResult<>0 Then Exit;
 For P:=P1 To P2 Do Begin
  Started:=False;
  If (P>=HFFrom) And (St[1].Len>0) Then Begin
   GetLines(1,Lt,Nt);
   For I:=0 To Nt-1 Do WriteLn(F,AlignText(LineText(1,Lt,I),St[1].Pa^[Lt^[I].Pa].Al,100));
   WriteLn(F);
  End;
  For I:=0 To NML-1 Do
   If (ML^[I].Reg Div NCols)+1=P Then Begin
    WriteLn(F,AlignText(LineText(0,ML,I),St[0].Pa^[ML^[I].Pa].Al,100));
    If (ML^[I].Fl And 2)<>0 Then WriteLn(F);
   End;
  If (P>=HFFrom) And (St[2].Len>0) Then Begin
   WriteLn(F);
   GetLines(2,Lt,Nt);
   For I:=0 To Nt-1 Do Begin
    S:=LineText(2,Lt,I);
    While Pos(#1,S)>0 Do Delete(S,Pos(#1,S),1);
    WriteLn(F,AlignText(S,St[2].Pa^[Lt^[I].Pa].Al,100));
   End;
  End;
  Write(F,#12);
 End;
 Close(F);
 PrintPages:=True;
End;

{ ====================================================================== }
{                           BOITES DE DIALOGUE                           }
{ ====================================================================== }

Function Clamp(V,Lo,Hi: LongInt): LongInt;
Begin
 If V<Lo Then V:=Lo;
 If V>Hi Then V:=Hi;
 Clamp:=V;
End;

{ Convertit les sequences `e `g ... en caracteres accentues (CP437) }
Function Fx(Const S: String): String;
Var I: Integer; R: String;
Begin
 R:='';I:=1;
 While I<=Length(S) Do Begin
  If (S[I]='`') And (I<Length(S)) Then Begin
   Case S[I+1] Of
    'e': R:=R+#130;
    'g': R:=R+#138;
    'x': R:=R+#136;
    'a': R:=R+#133;
    'c': R:=R+#135;
    'u': R:=R+#151;
    'o': R:=R+#147;
    'i': R:=R+#140;
    'w': R:=R+#150;
    't': R:=R+#139;
    'q': R:=R+#131;
    'E': R:=R+#144;
   Else R:=R+S[I+1];
   End;
   Inc(I,2);
  End Else Begin R:=R+S[I];Inc(I);End;
 End;
 Fx:=R;
End;

Procedure StdButtons(Y: Integer; WithApply: Boolean);
Begin
 CButton(1,14,Y,100,20,'OK',True,True);
 CButton(2,126,Y,100,20,'&Annuler',False,True);
 If WithApply Then Begin
  CButton(3,14,Y+26,100,20,'App&liquer',False,True);
  CButton(4,126,Y+26,100,20,'&R`etablir',False,True);
 End;
End;

Procedure BuildDlg(Id: Integer);
Var I,Y,V: Integer; Pr: TPara; Pn: Integer; S: String;
Begin
 Case Id Of
  1: Begin
    DlgInit(1,300,346,'Mise en page');
    CPopup(20,14,TBH+10,272,2,PgFmt+1);
    CGroup(10,TBH+40,280,92,Fx('Marges du texte (mm)'));
    CLabel(22,TBH+62,'gauche');CEdit(11,84,TBH+58,50,IntStr(MarL),'',True);
    CLabel(152,TBH+62,'droite');CEdit(12,208,TBH+58,50,IntStr(MarR),'',True);
    CLabel(22,TBH+86,'haut');CEdit(13,84,TBH+82,50,IntStr(MarT),'',True);
    CLabel(152,TBH+86,'bas');CEdit(14,208,TBH+82,50,IntStr(MarB),'',True);
    CCheck(15,22,TBH+108,'miroir droite/gauche',Mirror);
    CGroup(10,TBH+140,280,60,'Dans la zone de texte');
    CLabel(22,TBH+160,Fx('En-t`ete'));CEdit(16,150,TBH+156,50,IntStr(HeadH),'mm',True);
    CLabel(22,TBH+180,'Pied de page');CEdit(17,150,TBH+176,50,IntStr(FootH),'mm',True);
    CGroup(10,TBH+208,280,60,'Colonnes');
    CLabel(22,TBH+228,'Nombre');CPopup(18,150,TBH+224,50,4,NCols);
    CLabel(22,TBH+248,'Intervalle');CEdit(19,150,TBH+244,50,IntStr(ColGap),'mm',True);
    StdButtons(TBH+276,True);
   End;
  2: Begin
    DlgInit(2,430,TBH+250,Fx('D`ecalages de page'));
    CLabel(16,TBH+16,Fx('Num`erotation des pages, d`ebut:'));
    CEdit(1,340,TBH+12,50,IntStr(PgStart),'',True);
    CLabel(16,TBH+42,Fx('En-t`ete/pied `a partir de la page:'));
    CEdit(2,340,TBH+38,50,IntStr(HFFrom),'',True);
    CGroup(12,TBH+68,406,142,Fx('Zone des notes de bas de page'));
    CLabel(24,TBH+92,'Distance texte-filet:');CEdit(3,280,TBH+88,70,IntStr(FnA),'mm',True);
    CLabel(24,TBH+114,'Distance filet-note:');CEdit(4,280,TBH+110,70,IntStr(FnB),'mm',True);
    CLabel(24,TBH+136,Fx('Epaisseur du filet:'));CEdit(5,280,TBH+132,70,IntStr(FnC),'mm',True);
    CLabel(24,TBH+158,'Longueur du filet:');CEdit(6,280,TBH+154,70,IntStr(FnD),'mm',True);
    CLabel(24,TBH+180,Fx('D`ecalage bord gauche:'));CEdit(7,280,TBH+176,70,IntStr(FnE),'mm',True);
    CButton(1,16,TBH+218,110,20,'OK',True,True);
    CButton(2,150,TBH+218,110,20,'&Annuler',False,True);
   End;
  3: Begin
    DlgInit(3,300,TBH+118,Fx('C`esure'));
    CCheck(1,100,TBH+14,'couper les mots',HyphOn);
    CLabel(20,TBH+44,'Langue:');CPopup(2,100,TBH+38,170,1,HyphLang);
    CButton(1,14,TBH+76,70,20,'OK',True,True);
    CButton(3,110,TBH+76,80,20,'&setzen',False,True);
    CButton(4,214,TBH+76,70,20,Fx('&r`etablir'),False,True);
   End;
  4: Begin
    DlgInit(4,300,TBH+210,'Angle du texte');
    CButton(10+1,110,TBH+14,64,24,'90'#248,False,True);
    CButton(10+2,26,TBH+60,64,24,'180'#248,False,True);
    CButton(10+0,194,TBH+60,64,24,'0'#248,False,True);
    CButton(10+3,110,TBH+106,64,24,'270'#248,False,True);
    CButton(1,26,TBH+154,100,20,'OK',True,True);
    CButton(2,160,TBH+154,100,20,'&Annuler',False,True);
   End;
  5: Begin
    DlgInit(5,240,TBH+9*22+70,'Couleur du texte/objet');
    If (SelA>=0) Or (SelObj=0) Then V:=TypF Shr 4 Else V:=Obj[SelObj].Col;
    If V>8 Then V:=1;
    For I:=0 To 8 Do Begin
     CRadio(0,1,I,24,TBH+12+I*22,'',I=V);
     CSwatch(48,TBH+12+I*22,I);
     CLabel(76,TBH+15+I*22,ColName[I]);
    End;
    StdButtons(TBH+9*22+22,False);
   End;
  6: Begin
    Pn:=ParaOf(ASt,Cur);Pr:=St[ASt].Pa^[Pn];
    DlgInit(6,360,TBH+240,'Paragraphe');
    CLabel(16,TBH+16,'Retrait gauche:');CEdit(1,200,TBH+12,60,IntStr(Pr.LI Div 10),'mm',True);
    CLabel(16,TBH+40,'Retrait 1re ligne:');CEdit(2,200,TBH+36,60,IntStr(Pr.FI Div 10),'mm',True);
    CLabel(16,TBH+64,Fx('Espace apr`es:'));CEdit(3,200,TBH+60,60,IntStr(Pr.SA Div 10),'mm',True);
    CLabel(16,TBH+88,'Interligne (x0,1):');CEdit(4,200,TBH+84,60,IntStr(Pr.Spc),'',True);
    CGroup(12,TBH+114,336,50,'Alignement');
    CRadio(0,1,0,24,TBH+134,'gauche',Pr.Al=0);
    CRadio(0,1,1,104,TBH+134,Fx('justifi`e'),Pr.Al=1);
    CRadio(0,1,2,200,TBH+134,Fx('centr`e'),Pr.Al=2);
    CRadio(0,1,3,280,TBH+134,'droite',Pr.Al=3);
    CButton(10,14,TBH+176,180,20,Fx('Effacer les tabulations'),False,True);
    CButton(1,14,TBH+204,100,20,'OK',True,True);
    CButton(2,126,TBH+204,100,20,'&Annuler',False,True);
   End;
  7: Begin
    DlgInit(7,380,TBH+120,'Chercher');
    CLabel(16,TBH+18,'Texte:');CEdit(1,76,TBH+14,290,FindStr,'',False);
    CCheck(2,76,TBH+42,'respecter la casse',FindCase);
    CButton(10,14,TBH+76,170,20,'Chercher &suivant',True,True);
    CButton(2,230,TBH+76,100,20,'&Fermer',False,True);
   End;
  8: Begin
    DlgInit(8,400,TBH+170,'Remplacer');
    CLabel(16,TBH+18,'Chercher:');CEdit(1,120,TBH+14,264,FindStr,'',False);
    CLabel(16,TBH+44,'Remplacer par:');CEdit(2,120,TBH+40,264,ReplStr,'',False);
    CCheck(3,120,TBH+68,'respecter la casse',FindCase);
    CButton(10,14,TBH+102,120,20,'&Chercher',True,True);
    CButton(11,140,TBH+102,120,20,'&Remplacer',False,True);
    CButton(12,266,TBH+102,120,20,'&Tout',False,True);
    CButton(2,14,TBH+130,120,20,'&Fermer',False,True);
   End;
  9: Begin
    DlgInit(9,520,TBH+10*24+76,'Touches de fonction');
    CLabel(70,TBH+6,'Police');CLabel(290,TBH+6,'Style');
    For I:=1 To 10 Do Begin
     Y:=TBH+18+(I-1)*24;
     CLabel(16,Y+5,'F'+IntStr(I));
     CPopup(10+I,52,Y,210,6,FKFont[I]+1);
     CPopup(30+I,282,Y,210,7,FKStyle[I]+1);
    End;
    CButton(1,14,TBH+10*24+32,100,20,'OK',True,True);
    CButton(2,126,TBH+10*24+32,100,20,'&Annuler',False,True);
   End;
  10: Begin
    DlgInit(10,290,TBH+210,'Attributs de l''objet');
    CGroup(12,TBH+10,260,110,'Remplissage');
    CRadio(0,1,0,28,TBH+28,'aucun',Obj[SelObj].Fill=0);
    CRadio(0,1,1,28,TBH+46,'clair',Obj[SelObj].Fill=1);
    CRadio(0,1,2,28,TBH+64,'gris',Obj[SelObj].Fill=2);
    CRadio(0,1,3,150,TBH+28,Fx('fonc`e'),Obj[SelObj].Fill=3);
    CRadio(0,1,4,150,TBH+46,'noir',Obj[SelObj].Fill=4);
    CLabel(16,TBH+134,'Bordure (pixels):');CEdit(1,170,TBH+130,50,IntStr(Obj[SelObj].Bord),'',True);
    CButton(1,14,TBH+166,100,20,'OK',True,True);
    CButton(2,126,TBH+166,100,20,'&Annuler',False,True);
   End;
  11: Begin
    DlgInit(11,280,TBH+110,'Police');
    CLabel(16,TBH+18,'Police:');
    V:=(TypF Shr 3) And 1;
    CPopup(1,90,TBH+12,160,6,V*8+(TypF And 7)+2);
    CButton(1,14,TBH+60,100,20,'OK',True,True);
    CButton(2,140,TBH+60,100,20,'&Annuler',False,True);
   End;
 End;
End;

Procedure DlgApply(Id: Integer);
Var I,Pn,P1,P2: Integer; V: Integer;
Begin
 Case Id Of
  1: Begin
    SetPageFormat(CVal(20)-1);
    MarL:=Clamp(CNum(11,MarL),0,100);MarR:=Clamp(CNum(12,MarR),0,100);
    MarT:=Clamp(CNum(13,MarT),0,100);MarB:=Clamp(CNum(14,MarB),0,100);
    Mirror:=CChk(15);
    HeadH:=Clamp(CNum(16,HeadH),0,100);FootH:=Clamp(CNum(17,FootH),0,100);
    NCols:=Clamp(CVal(18),1,4);
    ColGap:=Clamp(CNum(19,ColGap),0,50);
    If MarL+MarR>PgW Div 10-30 Then Begin MarL:=20;MarR:=20;End;
    Relayout;Modified:=True;
   End;
  2: Begin
    PgStart:=Clamp(CNum(1,PgStart),0,9999);HFFrom:=Clamp(CNum(2,HFFrom),1,MAXPG);
    FnA:=Clamp(CNum(3,FnA),0,99);FnB:=Clamp(CNum(4,FnB),0,99);FnC:=Clamp(CNum(5,FnC),0,99);
    FnD:=Clamp(CNum(6,FnD),0,999);FnE:=Clamp(CNum(7,FnE),0,99);
    Relayout;Modified:=True;
   End;
  3: Begin
    HyphOn:=CChk(1);HyphLang:=Clamp(CVal(2),1,6);
    Relayout;Modified:=True;
   End;
  5: Begin
    V:=CRad(1);
    If (SelA>=0) Or (SelObj=0) Then SetColorIdx(V) Else Begin
     Obj[SelObj].Col:=V;Modified:=True;
    End;
   End;
  6: Begin
    BeginEdit(False);
    ParaRange(P1,P2);
    For Pn:=P1 To P2 Do With St[ASt].Pa^[Pn] Do Begin
     LI:=Clamp(CNum(1,0),0,1000)*10;FI:=Clamp(CNum(2,0),-500,1000)*10;
     SA:=Clamp(CNum(3,0),0,500)*10;Spc:=Clamp(CNum(4,14),8,40);
     Al:=CRad(1);Fm:=0;
    End;
    Relayout;
   End;
  10: Begin
    Obj[SelObj].Fill:=CRad(1);
    Obj[SelObj].Bord:=Clamp(CNum(1,1),0,8);
    Modified:=True;
   End;
  11: Begin
    V:=CVal(1)-2;
    If V>=0 Then SetFont(V Div 8,V Mod 8);
   End;
 End;
End;

Procedure DlgRevert(Id: Integer);
Begin
 If Id In [1,2,3] Then Begin RestoreSnap;BuildDlg(Id);End;
End;

{ Dialogue modal avec instantane (mise en page, decalages, cesure) }
Procedure OpenDlg(Id: Integer);
Begin
 SaveSnap;
 BuildDlg(Id);
 If RunDialog=1 Then DlgApply(Id) Else RestoreSnap;
 Relayout;
 NeedDraw:=True;
End;

Function AskFile(Const Title,Mask: String; Var Name: String): Boolean;
Var SR: SearchRec; N,I,Y: Integer; Names: Array[1..24] Of String[12];
Begin
 N:=0;
 FindFirst(Mask,AnyFile-Directory,SR);
 While (DosError=0) And (N<24) Do Begin
  Inc(N);Names[N]:=SR.Name;
  FindNext(SR);
 End;
 {$IFDEF FPC}
 FindClose(SR);
 {$ENDIF}
 Y:=TBH+30+((N+3) Div 4)*14;
 DlgInit(96,468,Y+64,Title);
 CLabel(16,TBH+10,'Fichiers ('+Mask+') :');
 For I:=1 To N Do CLabel(16+((I-1) Mod 4)*108,TBH+26+((I-1) Div 4)*14,Names[I]);
 CLabel(16,Y+4,'Nom :');
 CEdit(1,64,Y,380,Name,'',False);
 CButton(1,16,Y+30,80,20,'OK',True,True);
 CButton(2,372,Y+30,80,20,'&Annuler',False,True);
 If RunDialog=1 Then Begin Name:=CStr(1);AskFile:=Name<>'';End
 Else AskFile:=False;
End;

{ ====================================================================== }
{                              COMMANDES                                 }
{ ====================================================================== }

Procedure CmdAbout;
Begin
 MsgBox('A propos',
   'Papyrus '+VERSION_TEXT+' - clone du traitement de texte|'+
   Fx('multilingue Papyrus (Atari ST).')+'|'+
   'Ecrit en Pascal (Turbo Pascal 7 / Free Pascal).|'+
   'OFFICE-0 - https://www.gladir.com/office-0');
End;

Procedure CmdStats;
Var I,Words,Chars,Pars,InW: Integer; N: Integer;
Begin
 EnsureLayout;
 Words:=0;Chars:=0;InW:=0;
 With St[0] Do Begin
  For I:=0 To Len-1 Do Begin
   If IsLetter(T^[I]) Or ((T^[I]>=48) And (T^[I]<=57)) Then Begin
    If InW=0 Then Inc(Words);
    InW:=1;
   End Else InW:=0;
   If T^[I]>=32 Then Inc(Chars);
  End;
  Pars:=NP;
 End;
 MsgBox('Statistiques','Mots : '+IntStr(Words)+'|Caract'+#138+'res : '+IntStr(Chars)+
   '|Paragraphes : '+IntStr(Pars)+'|Lignes : '+IntStr(NML)+'|Pages : '+IntStr(NPages)+
   '|Objets : '+IntStr(NObj));
End;

Procedure SetZoom(Z: Integer);
Var Pg: Integer;
Begin
 Pg:=TopPage;
 Zoom:=Clamp(Z,25,300);
 ScrY:=LongInt(Pg-1)*StridePx;
 ClampScroll;
 NeedDraw:=True;
End;

Procedure ZoomFit(Whole: Boolean);
Var Z: LongInt;
Begin
 CalcGeo;
 If Whole Then Z:=LongInt(VY2-VY1-12)*100000 Div (268*PgH)
 Else Z:=LongInt(VX2-VX1-22)*100000 Div (268*PgW);
 SetZoom(Z);
End;

Procedure GotoPage(P: Integer);
Begin
 P:=Clamp(P,1,NPages);
 ScrY:=LongInt(P-1)*StridePx;
 CurPg:=P;
 ClampScroll;NeedDraw:=True;
End;

Procedure CmdGoto;
Var S: String;
Begin
 S:=IntStr(TopPage);
 If InputBox(Fx(#133+' la page'),'Num'+#130+'ro de page :',S,6) Then GotoPage(ValInt(S,1));
End;

Procedure CmdNew;
Begin
 If Modified Then
  If Not ConfirmBox(Fx('Abandonner les modifications ?')) Then Exit;
 NewDoc;DefaultConfig;NeedDraw:=True;
End;

Procedure CmdOpen;
Var N: String;
Begin
 If Modified Then
  If Not ConfirmBox(Fx('Abandonner les modifications ?')) Then Exit;
 N:='';
 If Not AskFile('Ouvrir','*.PAP',N) Then Exit;
 N:=AddExt(N,'PAP');
 If Not LoadPAP(N) Then Begin
  MsgBox('Erreur','Impossible de lire le fichier '+N);
  NewDoc;
 End;
 NeedDraw:=True;
End;

Procedure CmdSaveAs;
Var N: String;
Begin
 N:=DocName;
 If N='' Then N:='SANS_NOM.PAP';
 If Not AskFile('Enregistrer sous','*.PAP',N) Then Exit;
 N:=AddExt(N,'PAP');
 If SavePAP(N) Then Begin DocName:=N;Named:=True;Modified:=False;End
 Else MsgBox('Erreur',Fx('Ecriture impossible : ')+N);
 NeedDraw:=True;
End;

Procedure CmdSave;
Begin
 If Not Named Then Begin CmdSaveAs;Exit;End;
 If SavePAP(DocName) Then Modified:=False
 Else MsgBox('Erreur',Fx('Ecriture impossible : ')+DocName);
 NeedDraw:=True;
End;

Procedure CmdImport;
Var N: String;
Begin
 N:='';
 If Not AskFile('Importer un texte','*.TXT',N) Then Exit;
 If Not ImportASCII(N) Then MsgBox('Erreur','Impossible de lire '+N);
 NeedDraw:=True;
End;

Procedure CmdExport;
Var N: String;
Begin
 N:='SORTIE.TXT';
 If Not InputBox('Exporter le texte','Fichier :',N,30) Then Exit;
 If Not ExportASCII(N) Then MsgBox('Erreur',Fx('Ecriture impossible : ')+N)
 Else MsgBox('Exporter',Fx('Texte export`e dans ')+N);
End;

Procedure CmdQuit;
Begin
 If Modified Then
  If Not ConfirmBox(Fx('Quitter sans enregistrer ?')) Then Exit;
 Quit:=True;
End;

Procedure CmdPrint(All: Boolean);
Var P1,P2: Integer; Ok: Boolean;
Begin
 If All Then Begin P1:=1;P2:=NPages;End Else Begin P1:=CurPg;P2:=CurPg;End;
 Ok:=PrintPages(P1,P2);
 If Ok Then MsgBox('Imprimer',Fx('Impression termin`ee (')+IntStr(P2-P1+1)+' page(s).|Destination : '+PrintDest)
 Else MsgBox('Imprimer',Fx('Impression impossible.'));
End;

Procedure CmdPrintDest;
Var S: String;
Begin
 S:=PrintDest;
 If InputBox('Destination d''impression','Fichier ou PRN :',S,40) Then PrintDest:=S;
End;

Var SavedZoom: Integer;

Procedure CmdPreview;
Begin
 Preview:=Not Preview;
 If Preview Then Begin SavedZoom:=Zoom;ZoomFit(True);End
 Else SetZoom(SavedZoom);
 NeedDraw:=True;
End;

Procedure CmdFind(Replace: Boolean);
Var R,Cnt: Integer;
 Procedure ReplaceSel;
 Var A,B,I: Integer;
 Begin
  If Not SelRange(A,B) Then Exit;
  BeginEdit(False);
  StDel(ASt,A,B);Cur:=A;
  For I:=1 To Length(ReplStr) Do
   If StIns(ASt,Cur,Ord(ReplStr[I]),TypA,TypF) Then Inc(Cur);
  SelA:=-1;Relayout;Inc(Cnt);
 End;
Begin
 If Replace Then BuildDlg(8) Else BuildDlg(7);
 Cnt:=0;
 Repeat
  R:=RunDialog;
  FindStr:=CStr(1);
  If Replace Then Begin ReplStr:=CStr(2);FindCase:=CChk(3);End Else FindCase:=CChk(2);
  Case R Of
   10: Begin
     If Not FindText(True) Then MsgBox('Chercher',Fx('Texte introuvable.'));
     DrawAll;
    End;
   11: Begin
     ReplaceSel;
     If Not FindText(True) Then MsgBox('Remplacer',Fx('Plus d''occurrence.'));
     DrawAll;
    End;
   12: Begin
     Cnt:=0;Cur:=0;SelA:=-1;
     While FindText(False) Do ReplaceSel;
     MsgBox('Remplacer',IntStr(Cnt)+Fx(' remplacement(s).'));
     DrawAll;
    End;
  End;
  If R In [10,11,12] Then Begin
   If Replace Then BuildDlg(8) Else BuildDlg(7);
  End;
 Until Not (R In [10,11,12]);
 NeedDraw:=True;
End;

Procedure CmdColor;
Begin
 BuildDlg(5);
 If RunDialog=1 Then DlgApply(5);
 NeedDraw:=True;
End;

Procedure CmdParagraph;
Var R: Integer; P1,P2,I: Integer;
Begin
 BuildDlg(6);
 R:=RunDialog;
 If R=1 Then DlgApply(6)
 Else If R=10 Then Begin
  BeginEdit(False);
  ParaRange(P1,P2);
  For I:=P1 To P2 Do St[ASt].Pa^[I].NT:=0;
  Relayout;
 End;
 NeedDraw:=True;
End;

Procedure CmdAngle;
Var R: Integer;
Begin
 If (SelObj=0) Or (Obj[SelObj].Kind<>OB_TEXT) Then Begin
  MsgBox('Angle du texte',Fx('S`electionnez un cadre de texte.'));Exit;
 End;
 BuildDlg(4);
 R:=RunDialog;
 If (R>=10) And (R<=13) Then Begin Obj[SelObj].Ang:=R-10;Modified:=True;Relayout;End;
 NeedDraw:=True;
End;

Procedure CmdObjAttr;
Begin
 If SelObj=0 Then Exit;
 BuildDlg(10);
 If RunDialog=1 Then DlgApply(10);
 NeedDraw:=True;
End;

Procedure CmdFont;
Begin
 BuildDlg(11);
 If RunDialog=1 Then DlgApply(11);
 NeedDraw:=True;
End;

Procedure CmdFKeys;
Var K: Integer;
Begin
 BuildDlg(9);
 If RunDialog=1 Then Begin
  For K:=1 To 10 Do Begin
   FKFont[K]:=CVal(10+K)-1;
   FKStyle[K]:=CVal(30+K)-1;
  End;
 End;
 NeedDraw:=True;
End;

Procedure CmdFormats;
Var R,I,Cur_: Integer; S: String; Pn: Integer;
Begin
 Repeat
  Pn:=St[ASt].Pa^[ParaOf(ASt,Cur)].Fm;
  DlgInit(12,300,TBH+MAXFMT*20+90,'Formats');
  For I:=1 To NFmt Do CRadio(0,1,I,24,TBH+12+(I-1)*20,Fmts[I].Name,I=Pn);
  If NFmt=0 Then CLabel(24,TBH+14,Fx('(aucun format d`efini)'));
  CButton(1,14,TBH+MAXFMT*20+24,100,20,'Appliquer',True,True);
  CButton(10,126,TBH+MAXFMT*20+24,150,20,'&Nouveau...',False,True);
  CButton(11,14,TBH+MAXFMT*20+50,100,20,'&Supprimer',False,True);
  CButton(2,126,TBH+MAXFMT*20+50,100,20,'&Fermer',False,True);
  R:=RunDialog;
  Cur_:=CRad(1);
  If R=1 Then Begin If Cur_>0 Then ApplyFormat(Cur_);End
  Else If R=10 Then Begin
   S:='Format '+IntStr(NFmt+1);
   If (NFmt<MAXFMT) And InputBox('Nouveau format','Nom :',S,18) Then Begin
    Inc(NFmt);Fmts[NFmt].Name:=Copy(S,1,18);
    Fmts[NFmt].Fam:=(TypF Shr 3) And 1;Fmts[NFmt].Sz:=TypF And 7;
    Fmts[NFmt].At:=TypA;
    Fmts[NFmt].Al:=St[ASt].Pa^[ParaOf(ASt,Cur)].Al;
    Fmts[NFmt].Spc:=St[ASt].Pa^[ParaOf(ASt,Cur)].Spc;
    St[ASt].Pa^[ParaOf(ASt,Cur)].Fm:=NFmt;
    Modified:=True;
   End;
  End Else If R=11 Then Begin
   If (Cur_>0) And (Cur_<=NFmt) Then Begin
    For I:=0 To St[ASt].NP-1 Do
     If St[ASt].Pa^[I].Fm=Cur_ Then St[ASt].Pa^[I].Fm:=0
     Else If St[ASt].Pa^[I].Fm>Cur_ Then Dec(St[ASt].Pa^[I].Fm);
    For I:=Cur_ To NFmt-1 Do Fmts[I]:=Fmts[I+1];
    Dec(NFmt);Modified:=True;
   End;
  End;
 Until (R=1) Or (R=2);
 Relayout;NeedDraw:=True;
End;

Procedure CmdFormatPopup(X,Y: Integer);
Var Pn,R: Integer;
Begin
 Pn:=St[ASt].Pa^[ParaOf(ASt,Cur)].Fm;
 R:=PopupAt(X,Y,116,3,Pn+1);
 If R>0 Then ApplyFormat(R-1);
 NeedDraw:=True;
End;

{ ---- creation d'objets ---- }
Procedure CmdNewObject(AKind: Byte; AFill: Byte);
Var O,Pg: Integer;
Begin
 Pg:=TopPage;
 Case AKind Of
  OB_TEXT: O:=NewObject(AKind,Pg,BodyX(Pg)+100,BodyYd+100,700,300);
  OB_LINE: O:=NewObject(AKind,Pg,BodyX(Pg),BodyYd+200,TextWd,20);
  Else O:=NewObject(AKind,Pg,BodyX(Pg)+100,BodyYd+100,600,400);
 End;
 If O=0 Then Begin MsgBox('Objet',Fx('Impossible de cr`eer l''objet.'));Exit;End;
 Obj[O].Fill:=AFill;
 SelObj:=O;Tool:=TL_SEL;
 NeedDraw:=True;
End;

Procedure CmdImage;
Var N: String; O,Pg: Integer;
Begin
 N:='';
 Pg:=TopPage;
 If Not InputBox('Image PBM',Fx('Fichier (vide = logo interne) :'),N,30) Then Exit;
 O:=NewObject(OB_IMAGE,Pg,BodyX(Pg)+100,BodyYd+100,640,400);
 If O=0 Then Exit;
 If N='' Then MakeLogo(O)
 Else If Not LoadPBM(AddExt(N,'PBM'),O) Then Begin
  MsgBox('Image',Fx('Impossible de lire l''image (PBM P4 attendu).'));
 End;
 SelObj:=O;Tool:=TL_SEL;
 NeedDraw:=True;
End;

{ ---- document de demonstration ---- }
Procedure DAdd(Const S: String; At,Sz,Fam: Byte);
Begin
 StAppend(0,Fx(S),At,Sz Or (Fam Shl 3) Or (1 Shl 4));
End;

Procedure DEnd(Al,Spc,SA: Integer);
Var Pn: Integer;
Begin
 StIns(0,St[0].Len,13,0,DEFF);
 Pn:=St[0].NP-2;
 St[0].Pa^[Pn].Al:=Al;St[0].Pa^[Pn].Spc:=Spc;St[0].Pa^[Pn].SA:=SA;
 DefPara(St[0].Pa^[St[0].NP-1]);
End;

Procedure DTabs(A,K1,B,K2,C,K3: Integer);
Var Pn: Integer;
Begin
 Pn:=St[0].NP-2;
 With St[0].Pa^[Pn] Do Begin
  NT:=3;Tb[1].P:=A;Tb[1].K:=K1;Tb[2].P:=B;Tb[2].K:=K2;Tb[3].P:=C;Tb[3].K:=K3;
 End;
End;

Procedure MakeDemo;
Var O,I: Integer; Pn: Integer;
Begin
 NewDoc;
 DefaultConfig;
 HeadH:=40;FootH:=15;NCols:=1;
 { en-tete : titre et sous-titre }
 StAppend(1,'Papyrus',A_BOLD,5 Or (1 Shl 3) Or (1 Shl 4));
 StIns(1,St[1].Len,13,0,DEFF);
 StAppend(1,Fx('traitement de texte multilingue'),A_ITAL,3 Or (1 Shl 3) Or (1 Shl 4));
 St[1].Pa^[0].SA:=0;
 { pied : numero de page centre }
 StAppend(2,'- ',0,DEFF);
 StIns(2,St[2].Len,1,0,DEFF);
 StAppend(2,' -',0,DEFF);
 St[2].Pa^[0].Al:=2;
 { corps du texte }
 DAdd('Pr`esentation de Papyrus',A_BOLD,4,1);DEnd(0,14,40);
 DAdd('Papyrus est un traitement de texte multilingue de type WYSIWYG : le document '+
   's''affiche `a l''`ecran tel qu''il sera imprim`e, avec ses colonnes, son en-t`ete, '+
   'son pied de page et ses cadres. ',0,2,0);
 DAdd('Les menus d`eroulants, la palette d''outils et la '+
   'barre de touches de fonction rappellent la version Atari ST.',0,2,0);
 DEnd(1,14,60);
 DAdd('Mise en forme',A_BOLD,3,1);DEnd(0,14,30);
 DAdd('Les styles de caract`eres sont accessibles au clavier (F1 `a F10) : ',0,2,0);
 DAdd('gras',A_BOLD,2,0);DAdd(', ',0,2,0);
 DAdd('italique',A_ITAL,2,0);DAdd(', ',0,2,0);
 DAdd('soulign`e',A_UND,2,0);DAdd(', ',0,2,0);
 DAdd('contour',A_OUT,2,0);DAdd(', ',0,2,0);
 DAdd('clair',A_LIGHT,2,0);DAdd(', x',0,2,0);
 DAdd('2',A_SUP,2,0);DAdd(' et H',0,2,0);
 DAdd('2',A_SUB,2,0);DAdd('O. ',0,2,0);
 DAdd('Les alignements gauche, justifi`e, centr`e et droite se choisissent dans la barre '+
   'de format ; l''interligne se r`egle avec les fl`eches.',0,2,0);
 DEnd(1,14,60);
 DAdd('C`esure',A_BOLD,3,1);DEnd(0,14,30);
 DAdd('La c`esure automatique, disponible en allemand, fran`cais, italien, anglais, '+
   'espagnol et turc, donne un gris typographique r`egulier en texte justifi`e : ',0,2,0);
 DAdd('extraordinairement, constitutionnellement, internationalisation, '+
   'incompr`ehensiblement.',0,2,0);
 DEnd(1,14,60);
 DAdd('Tabulations',A_BOLD,3,1);DEnd(0,14,30);
 DAdd('Article'#9'Langue'#9'Version'#9'Prix',A_BOLD,2,1);DEnd(0,14,0);DTabs(500,0,1100,1,1600,3);
 DAdd('Papyrus'#9'Fran`cais'#9'1.00'#9'299,00',0,2,0);DEnd(0,14,0);DTabs(500,0,1100,1,1600,3);
 DAdd('Papyrus'#9'Allemand'#9'1.00'#9'149,50',0,2,0);DEnd(0,14,0);DTabs(500,0,1100,1,1600,3);
 DAdd('Modules'#9'Italien'#9'0.90'#9'49,95',0,2,0);DEnd(0,14,60);DTabs(500,0,1100,1,1600,3);
 DAdd('Colonnes, cadres et objets',A_BOLD,3,1);DEnd(0,14,30);
 DAdd('La commande Mise en page du menu Texte r`egle les marges, les zones d''en-t`ete et '+
   'de pied, le nombre de colonnes et leur intervalle. ',0,2,0);
 DAdd('La palette d''outils permet de '+
   'tracer des cadres de texte, des rectangles `a fond clair, gris ou fonc`e ; ',0,2,0);
 DAdd('un cadre '+
   'de texte peut `etre tourn`e de 90, 180 ou 270 degr`es. Glissez un objet sur la '+
   'corbeille pour le supprimer.',0,2,0);
 DEnd(1,14,60);
 DAdd('Raccourcis clavier',A_BOLD,3,1);DEnd(0,14,30);
 DAdd('Ctrl+S'#9'Enregistrer',0,2,0);DEnd(0,14,0);DTabs(500,0,0,0,0,0);St[0].Pa^[St[0].NP-2].NT:=1;
 DAdd('Ctrl+F'#9'Chercher',0,2,0);DEnd(0,14,0);DTabs(500,0,0,0,0,0);St[0].Pa^[St[0].NP-2].NT:=1;
 DAdd('Ctrl+Z'#9'Annuler',0,2,0);DEnd(0,14,0);DTabs(500,0,0,0,0,0);St[0].Pa^[St[0].NP-2].NT:=1;
 DAdd('F9'#9+'Mode s`election (marqueur)',0,2,0);DEnd(0,14,0);DTabs(500,0,0,0,0,0);St[0].Pa^[St[0].NP-2].NT:=1;
 DAdd('Ctrl+Entr`ee'#9'Nouvelle ligne',0,2,0);DEnd(0,14,60);DTabs(500,0,0,0,0,0);St[0].Pa^[St[0].NP-2].NT:=1;
 DAdd('Fin du document de d`emonstration. Bonne utilisation de Papyrus !',A_ITAL,2,0);
 { objets : logo et cadre de texte dans la zone d'en-tete }
 O:=NewObject(OB_IMAGE,1,1350,100,650,380);
 If O>0 Then MakeLogo(O);
 O:=NewObject(OB_TEXT,1,1350,500,650,130);
 If O>0 Then Begin
  Obj[O].Bord:=1;
  StAppend(Obj[O].St,Fx('Distribution exclusive'),A_BOLD,2 Or (1 Shl 4));
  StIns(Obj[O].St,St[Obj[O].St].Len,13,0,DEFF);
  StAppend(Obj[O].St,'Gladir - OFFICE-0',0,DEFF);
  StAppend(Obj[O].St,'',0,DEFF);
 End;
 SelObj:=0;Tool:=TL_TEXT;ASt:=0;Cur:=0;SelA:=-1;
 Modified:=False;Relayout;
End;

{ ====================================================================== }
{                  EXECUTION DES COMMANDES DE MENU                       }
{ ====================================================================== }

Procedure FKeyStyle(Sty: Integer);
Var L: PLineArr; N: Integer;
Begin
 Case Sty Of
  1: ToggleStyle(A_BOLD);
  2: ToggleStyle(A_UND);
  3: ToggleStyle(A_ITAL);
  4: ToggleStyle(A_OUT);
  5: ToggleStyle(A_LIGHT);
  6: ToggleStyle(A_SUP);
  7: ToggleStyle(A_SUB);
  8: SetSpacing(16);
  9: InsChar(10);
  10: Begin
    MarkMode:=Not MarkMode;
    If MarkMode Then SelA:=Cur;
    NeedDraw:=True;
   End;
 End;
End;

Procedure FKeyFont(V: Integer);
Begin
 If V>0 Then SetFont((V-1) Div 8,(V-1) Mod 8);
End;

Procedure FKeyAction(K,Row: Integer);
Begin
 If Row=1 Then FKeyFont(FKFont[K])
 Else If Row=2 Then FKeyStyle(FKStyle[K])
 Else Begin FKeyFont(FKFont[K]);FKeyStyle(FKStyle[K]);End;
 NeedDraw:=True;
End;

Procedure DoMenu(M,I: Integer);
Begin
 Case M Of
  1: Case I Of
      1: CmdAbout;
      3: CmdStats;
      4: MsgBox('M'#130'moire libre','Cette version utilise le tas du syst'#138'me.');
     End;
  2: Case I Of
      1: CmdNew;
      2: CmdOpen;
      3: CmdSave;
      4: CmdSaveAs;
      6: CmdImport;
      7: CmdExport;
      9: CmdQuit;
     End;
  3: Case I Of
      1: CmdPrint(True);
      2: CmdPrint(False);
      4: CmdPreview;
      5: CmdPrintDest;
     End;
  4: Case I Of
      1: DoUndo;
      3: ClipCut;
      4: ClipCopy;
      5: ClipPaste;
      6: Begin BeginEdit(False);DelSel;Relayout;SyncTyp;NeedDraw:=True;End;
      7: SelectAll;
      9: CmdFind(False);
      10: CmdFind(True);
      11: Begin
        If Not FindText(True) Then MsgBox('Chercher',Fx('Texte introuvable.'));
       End;
      13: CmdGoto;
     End;
  5: Case I Of
      1: OpenDlg(1);
      2: OpenDlg(2);
      3: OpenDlg(3);
      5: CmdParagraph;
      6: CmdFormats;
      8..11: SetAlign(I-8);
      13: InsChar(12);
      14: InsChar(1);
     End;
  6: Case I Of
      1: PlainStyle;
      2: ToggleStyle(A_BOLD);
      3: ToggleStyle(A_ITAL);
      4: ToggleStyle(A_UND);
      5: ToggleStyle(A_OUT);
      6: ToggleStyle(A_LIGHT);
      7: ToggleStyle(A_SUP);
      8: ToggleStyle(A_SUB);
      10..13: SetFont(0,I-9);
      14..17: SetFont(1,I-13);
      19: CmdFont;
      20: CmdColor;
     End;
  7: Case I Of
      1: CmdNewObject(OB_TEXT,0);
      2: CmdNewObject(OB_RECT,0);
      3: CmdNewObject(OB_RECT,3);
      4: CmdNewObject(OB_RECT,2);
      5: CmdNewObject(OB_LINE,0);
      6: CmdImage;
      8: CmdObjAttr;
      9: CmdAngle;
      10: CmdColor;
      12: ObjToFront;
      13: ObjToBack;
      14: DeleteObject(SelObj);
     End;
  8: Case I Of
      1: SetZoom(50);
      2: SetZoom(75);
      3: SetZoom(100);
      4: SetZoom(150);
      5: SetZoom(200);
      7: ZoomFit(True);
      8: ZoomFit(False);
     End;
  9: Case I Of
      1: Begin ToolsOn:=Not ToolsOn;NeedDraw:=True;End;
      2: Begin RulerOn:=Not RulerOn;NeedDraw:=True;End;
      3: Begin FormatOn:=Not FormatOn;NeedDraw:=True;End;
      4: Begin GuidesOn:=Not GuidesOn;NeedDraw:=True;End;
      6: CmdFKeys;
      8: SaveConfig;
     End;
 End;
 NeedDraw:=True;
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
  If (Not MSep(M,I)) And MEnabled(M,I) Then Begin NextItem:=I;Exit;End;
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
          If (H<>0) And (MSep(M,H) Or Not MEnabled(M,H)) Then H:=0;
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
       K_LEFT: Begin Dec(M);If M<1 Then M:=NMENU;Hi:=NextItem(M,0,1);Redraw:=True;End;
       K_RIGHT: Begin Inc(M);If M>NMENU Then M:=1;Hi:=NextItem(M,0,1);Redraw:=True;End;
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
{                  SOURIS : POINTAGE DANS LE DOCUMENT                    }
{ ====================================================================== }

Var
 DrgObj    : Integer;
 DrgSel0   : Integer;
 LastClickX,LastClickY : LongInt;

Function PageAtPoint(X,Y: LongInt; Var Pg: Integer; Var Xd,Yd: LongInt): Boolean;
Var Dy: LongInt;
Begin
 PageAtPoint:=False;
 If (X<VX1) Or (X>VX2) Or (Y<VY1) Or (Y>VY2) Then Exit;
 Dy:=Y-(VY1+4-ScrY);
 If Dy<0 Then Exit;
 Pg:=Dy Div StridePx+1;
 If Pg>NPages Then Exit;
 Dy:=Dy Mod StridePx;
 If Dy>=PageHPx Then Exit;
 Xd:=P2D(X-PageX0);
 Yd:=P2D(Dy);
 If (Xd<0) Or (Xd>PgW) Then Exit;
 PageAtPoint:=True;
End;

Function ObjAt(Pg: Integer; Xd,Yd: LongInt): Integer;
Var I,Hh: Integer;
Begin
 ObjAt:=0;
 For I:=NObj Downto 1 Do
  If Obj[I].Pg=Pg Then Begin
   Hh:=Obj[I].H;
   If (Obj[I].Kind=OB_LINE) And (Hh<60) Then Hh:=60;
   If InBox(Xd,Yd,Obj[I].X-10,Obj[I].Y-10,Obj[I].X+Obj[I].W+10,Obj[I].Y+Hh+10) Then Begin
    ObjAt:=I;Exit;
   End;
  End;
End;

Function LineAtY(L: PLineArr; N: Integer; Reg: Integer; Ly: LongInt): Integer;
Var I,Best: Integer;
Begin
 Best:=-1;
 For I:=0 To N-1 Do
  If L^[I].Reg=Reg Then Begin
   If Best<0 Then Best:=I
   Else If L^[I].Y<=Ly Then Best:=I;
  End;
 LineAtY:=Best;
End;

Function HitText(X,Y: LongInt; Var S,Ps,Pg: Integer): Boolean;
Var Xd,Yd,Lx,Ly,Ox,Oy: LongInt; O,I,Col,Best: Integer; L: PLineArr; N: Integer;
Begin
 HitText:=False;
 If Not PageAtPoint(X,Y,Pg,Xd,Yd) Then Exit;
 For O:=NObj Downto 1 Do
  If (Obj[O].Kind=OB_TEXT) And (Obj[O].Pg=Pg) And
     InBox(Xd,Yd,Obj[O].X,Obj[O].Y,Obj[O].X+Obj[O].W,Obj[O].Y+Obj[O].H) Then Begin
   S:=Obj[O].St;
   Ox:=Xd-Obj[O].X;Oy:=Yd-Obj[O].Y;
   Case Obj[O].Ang And 3 Of
    1: Begin Lx:=Obj[O].H-Oy;Ly:=Ox;End;
    2: Begin Lx:=Obj[O].W-Ox;Ly:=Obj[O].H-Oy;End;
    3: Begin Lx:=Oy;Ly:=Obj[O].W-Ox;End;
   Else Begin Lx:=Ox;Ly:=Oy;End;
   End;
   Lx:=Lx-20;Ly:=Ly-20;
   LayoutBox(S);
   Best:=0;
   For I:=0 To NTL-1 Do If TLn^[I].Y<=Ly Then Best:=I;
   Ps:=PosAtX(S,TLn,Best,Lx);
   HitText:=True;Exit;
  End;
 If Pg>=HFFrom Then Begin
  If (HeadH>0) And InBox(Xd,Yd,BodyX(Pg),MarT*10,BodyX(Pg)+TextWd,(MarT+HeadH)*10) Then Begin
   S:=1;LayoutBox(1);
   Ly:=Yd-MarT*10;Best:=0;
   For I:=0 To NTL-1 Do If TLn^[I].Y<=Ly Then Best:=I;
   Ps:=PosAtX(1,TLn,Best,Xd-BodyX(Pg));
   HitText:=True;Exit;
  End;
  If (FootH>0) And InBox(Xd,Yd,BodyX(Pg),PgH-(MarB+FootH)*10,BodyX(Pg)+TextWd,PgH-MarB*10) Then Begin
   S:=2;LayoutBox(2);
   Ly:=Yd-(PgH-(MarB+FootH)*10);Best:=0;
   For I:=0 To NTL-1 Do If TLn^[I].Y<=Ly Then Best:=I;
   Ps:=PosAtX(2,TLn,Best,Xd-BodyX(Pg));
   HitText:=True;Exit;
  End;
 End;
 If (Yd>=BodyYd-50) And (Yd<=BodyYd+BodyHd+50) And (Xd>=BodyX(Pg)-100) And
    (Xd<=BodyX(Pg)+TextWd+100) Then Begin
  EnsureLayout;
  Col:=(Xd-BodyX(Pg)) Div (ColWd+ColGap*10);
  If Col<0 Then Col:=0;
  If Col>=NCols Then Col:=NCols-1;
  Lx:=Xd-(BodyX(Pg)+Col*(ColWd+ColGap*10));Ly:=Yd-BodyYd;
  Best:=LineAtY(ML,NML,(Pg-1)*NCols+Col,Ly);
  S:=0;
  If Best<0 Then Ps:=St[0].Len
  Else Ps:=PosAtX(0,ML,Best,Lx);
  HitText:=True;
 End;
End;

{ ====================================================================== }
{                              CLAVIER                                   }
{ ====================================================================== }

Function AltLetter(K: Word): Integer;
Const
 RowQ : String[10] = 'QWERTYUIOP';
 RowA : String[9] = 'ASDFGHJKL';
 RowZ : String[7] = 'ZXCVBNM';
Var Sc: Integer;
Begin
 AltLetter:=-1;
 If K<256 Then Exit;
 Sc:=K-256;
 Case Sc Of
  16..25: AltLetter:=Ord(RowQ[Sc-15])-65;
  30..38: AltLetter:=Ord(RowA[Sc-29])-65;
  44..50: AltLetter:=Ord(RowZ[Sc-43])-65;
 End;
End;

Procedure ScrollBy(DX,DY: LongInt);
Begin
 ScrX:=ScrX+DX;ScrY:=ScrY+DY;
 ClampScroll;
 NeedDraw:=True;
End;

Procedure MoveObj(DX,DY: Integer);
Begin
 If SelObj=0 Then Exit;
 Obj[SelObj].X:=Obj[SelObj].X+DX;Obj[SelObj].Y:=Obj[SelObj].Y+DY;
 Modified:=True;NeedDraw:=True;
End;

Procedure MenuByLetter(L: Integer);
Var M: Integer;
Begin
 M:=0;
 Case Chr(L+65) Of
  'P': M:=1;
  'F': M:=2;
  'I': M:=3;
  'E': M:=4;
  'T': M:=5;
  'S': M:=6;
  'O': M:=7;
  'Z': M:=8;
  'N': M:=9;
 End;
 If M>0 Then RunMenu(M,False);
End;

Procedure HandleKey(K: Word);
Var L: Integer;
Begin
 If K>=256 Then Begin
  L:=AltLetter(K);
  If L>=0 Then Begin MenuByLetter(L);Exit;End;
 End;
 If (K>=K_F1) And (K<=K_F1+9) Then Begin FKeyAction(K-K_F1+1,0);Exit;End;
 If (SelObj>0) And (Tool=TL_SEL) Then Begin
  Case K Of
   K_DEL: Begin DeleteObject(SelObj);Exit;End;
   K_LEFT: Begin MoveObj(-10,0);Exit;End;
   K_RIGHT: Begin MoveObj(10,0);Exit;End;
   K_UP: Begin MoveObj(0,-10);Exit;End;
   K_DOWN: Begin MoveObj(0,10);Exit;End;
  End;
 End;
 Case K Of
  K_ESC: Begin SelA:=-1;MarkMode:=False;SelObj:=0;NeedDraw:=True;End;
  K_ENTER: InsChar(13);
  10: InsChar(10);
  K_TAB: InsChar(9);
  K_BKSP: DoBackspace;
  K_DEL: DoDelete;
  K_LEFT: Begin MoveTo(Cur-1,False);WantX:=-1;End;
  K_RIGHT: Begin MoveTo(Cur+1,False);WantX:=-1;End;
  K_UP: CurUpDown(-1,False);
  K_DOWN: CurUpDown(1,False);
  K_HOME: CurLineEdge(True,False);
  K_END: CurLineEdge(False,False);
  K_CHOME: Begin MoveTo(0,False);WantX:=-1;End;
  K_CEND: Begin MoveTo(St[ASt].Len,False);WantX:=-1;End;
  K_CLEFT: CurWord(-1,False);
  K_CRIGHT: CurWord(1,False);
  K_PGUP: For L:=1 To 15 Do CurUpDown(-1,False);
  K_PGDN: For L:=1 To 15 Do CurUpDown(1,False);
  1: SelectAll;
  2: ToggleStyle(A_BOLD);
  3: ClipCopy;
  4: SetAlign(1);
  5: SetAlign(2);
  6: CmdFind(False);
  7: Begin
      If Not FindText(True) Then MsgBox('Chercher',Fx('Texte introuvable.'));
     End;
  12: SetAlign(0);
  14: CmdNew;
  15: CmdOpen;
  16: CmdPrint(True);
  17: CmdQuit;
  18: SetAlign(3);
  19: CmdSave;
  20: CmdGoto;
  21: ToggleStyle(A_UND);
  22: ClipPaste;
  23: CmdFind(True);
  24: ClipCut;
  26: DoUndo;
  32..255: InsChar(K);
 End;
End;

{ ====================================================================== }
{                              SOURIS                                    }
{ ====================================================================== }

Procedure VThumb(Y: LongInt);
Var TY1,TY2,TH: LongInt;
Begin
 TY1:=WY1+TBH+1+SBW;TY2:=WY2-SBW-SBW;
 TH:=(TY2-TY1) Div 4;If TH<14 Then TH:=14;
 If TY2-TY1-TH<=0 Then Exit;
 ScrY:=(Y-TY1-TH Div 2)*MaxScrY Div (TY2-TY1-TH);
 ClampScroll;NeedDraw:=True;
End;

Procedure HThumb(X: LongInt);
Var TX1,TX2,TW: LongInt;
Begin
 TX1:=WX1+1+SBW;TX2:=WX2-SBW-SBW;
 TW:=(TX2-TX1) Div 4;If TW<14 Then TW:=14;
 If TX2-TX1-TW<=0 Then Exit;
 ScrX:=(X-TX1-TW Div 2)*MaxScrX Div (TX2-TX1-TW);
 ClampScroll;NeedDraw:=True;
End;

Function SelectWord: Boolean;
Var Wa,Wb: Integer;
Begin
 SelectWord:=False;
 With St[ASt] Do Begin
  If Len=0 Then Exit;
  Wa:=Cur;Wb:=Cur;
  While (Wa>0) And IsLetter(T^[Wa-1]) Do Dec(Wa);
  While (Wb<Len) And IsLetter(T^[Wb]) Do Inc(Wb);
  If Wb>Wa Then Begin SelA:=Wa;Cur:=Wb;SelectWord:=True;End;
 End;
End;

Procedure DocMouseDown(X,Y: LongInt);
Var Pg,S,Ps,O: Integer; Xd,Yd: LongInt; T: LongInt; Dbl: Boolean; X2,Y2: LongInt;
Begin
 T:=Tick;
 Dbl:=(Abs(T-LastClickT)<45) And (Abs(X-LastClickX)<4) And (Abs(Y-LastClickY)<4);
 LastClickT:=T;LastClickX:=X;LastClickY:=Y;
 Case Tool Of
  TL_FRAME,TL_RECT,TL_DARK,TL_GREY: Begin
    If PageAtPoint(X,Y,Pg,Xd,Yd) Then Begin
     Case Tool Of
      TL_FRAME: O:=NewObject(OB_TEXT,Pg,Xd,Yd,10,10);
      TL_RECT: O:=NewObject(OB_RECT,Pg,Xd,Yd,10,10);
      TL_DARK: Begin O:=NewObject(OB_RECT,Pg,Xd,Yd,10,10);If O>0 Then Obj[O].Fill:=3;End;
      Else Begin O:=NewObject(OB_RECT,Pg,Xd,Yd,10,10);If O>0 Then Obj[O].Fill:=2;End;
     End;
     If O>0 Then Begin
      SelObj:=O;DrgObj:=O;Dragging:=4;DragOX:=Xd;DragOY:=Yd;
      NeedDraw:=True;
     End;
    End;
   End;
  TL_SEL: Begin
    If SelObj>0 Then Begin
     { poignee en bas a droite : redimensionnement }
     If PageAtPoint(X,Y,Pg,Xd,Yd) And (Pg=Obj[SelObj].Pg) Then
      If InBox(Xd,Yd,Obj[SelObj].X+Obj[SelObj].W-50,Obj[SelObj].Y+Obj[SelObj].H-50,
          Obj[SelObj].X+Obj[SelObj].W+50,Obj[SelObj].Y+Obj[SelObj].H+50) Then Begin
       Dragging:=3;DrgObj:=SelObj;Exit;
      End;
    End;
    If PageAtPoint(X,Y,Pg,Xd,Yd) Then Begin
     O:=ObjAt(Pg,Xd,Yd);
     If O>0 Then Begin
      SelObj:=O;DrgObj:=O;Dragging:=2;
      DragOX:=Xd-Obj[O].X;DragOY:=Yd-Obj[O].Y;
      If Dbl And (Obj[O].Kind=OB_TEXT) Then Begin
       Tool:=TL_TEXT;ASt:=Obj[O].St;Cur:=St[ASt].Len;SelA:=-1;Dragging:=0;SyncTyp;
      End;
      NeedDraw:=True;Exit;
     End;
    End;
    SelObj:=0;
    If HitText(X,Y,S,Ps,Pg) Then Begin
     ASt:=S;Cur:=Ps;SelA:=-1;If (S=1) Or (S=2) Then CurPg:=Pg Else CurPg:=Pg;
     SyncTyp;WantX:=-1;LastTyping:=False;
    End;
    NeedDraw:=True;
   End;
  TL_TEXT: Begin
    SelObj:=0;
    If HitText(X,Y,S,Ps,Pg) Then Begin
     ASt:=S;CurPg:=Pg;
     If ShiftDown Then Begin If SelA<0 Then SelA:=Cur;Cur:=Ps;End
     Else Begin
      Cur:=Ps;SelA:=Ps;MarkMode:=False;
      Dragging:=1;
      If Dbl Then Begin SelectWord;Dragging:=0;End;
     End;
     SyncTyp;WantX:=-1;LastTyping:=False;
    End;
    NeedDraw:=True;
   End;
 End;
End;

Procedure MouseDown(X,Y: LongInt);
Var T,N,Row,K,Pn: Integer; Xd: LongInt;
Begin
 T:=TitleHit(X,Y);
 If T>0 Then Begin RunMenu(T,True);Exit;End;
 N:=FKeyHit(X,Y,Row);
 If N>0 Then Begin FKeyAction(N,Row);Exit;End;
 K:=ToolHit(X,Y);
 If K>0 Then Begin
  Tool:=K;
  If K<>TL_SEL Then SelObj:=0;
  NeedDraw:=True;Exit;
 End;
 { barre de titre }
 If InBox(X,Y,WX1,WY1,WX1+TBH,WY1+TBH) Then Begin CmdQuit;Exit;End;
 If InBox(X,Y,WX2-TBH,WY1,WX2,WY1+TBH) Then Begin
  FullWin:=Not FullWin;NeedDraw:=True;Exit;
 End;
 { barre de format }
 K:=TbHit(X,Y);
 If K>0 Then Begin
  Pn:=ParaOf(ASt,Cur);
  Case K Of
   1: CmdFormatPopup(WX1+19,TbY1+34);
   2..5: SetAlign(K-2);
   6..9: Begin TabKind:=K-6;NeedDraw:=True;End;
   10: SetSpacing(St[ASt].Pa^[Pn].Spc+1);
   11: SetSpacing(St[ASt].Pa^[Pn].Spc-1);
   12: Begin HyphOn:=Not HyphOn;Relayout;Modified:=True;NeedDraw:=True;End;
   13: CmdGoto;
  End;
  Exit;
 End;
 { regle : pose d'un taquet }
 If RulerOn And InBox(X,Y,WX1+1,RulY1,WX2-SBW-1,RulY1+13) Then Begin
  Xd:=P2D(X-PageX0)-BodyX(CurPg);
  If (Xd>=0) And (Xd<=TextWd) Then SetTab(Xd,TabKind);
  Exit;
 End;
 { barres de defilement }
 If InBox(X,Y,WX2-SBW+1,WY1+TBH+1,WX2,WY2-SBW) Then Begin
  If Y<WY1+TBH+1+SBW Then ScrollBy(0,-30)
  Else If Y>WY2-SBW-SBW Then ScrollBy(0,30)
  Else Begin Dragging:=5;VThumb(Y);End;
  Exit;
 End;
 If InBox(X,Y,WX1+1,WY2-SBW+1,WX2-SBW,WY2-1) Then Begin
  If X<WX1+1+SBW Then ScrollBy(-30,0)
  Else If X>WX2-SBW-SBW Then ScrollBy(30,0)
  Else Begin Dragging:=6;HThumb(X);End;
  Exit;
 End;
 If InBox(X,Y,VX1,VY1,VX2,VY2) Then DocMouseDown(X,Y);
End;

Procedure MouseMove(X,Y: LongInt);
Var S,Ps,Pg: Integer; Xd,Yd: LongInt;
Begin
 If Dragging=0 Then Exit;
 Case Dragging Of
  1: Begin
      If Y<VY1 Then ScrollBy(0,-6) Else If Y>VY2 Then ScrollBy(0,6);
      If HitText(Max2(VX1,Min2(X,VX2)),Max2(VY1,Min2(Y,VY2)),S,Ps,Pg) Then
       If S=ASt Then Begin Cur:=Ps;NeedDraw:=True;End;
     End;
  2: If PageAtPoint(X,Y,Pg,Xd,Yd) Then Begin
      Obj[DrgObj].Pg:=Pg;
      Obj[DrgObj].X:=Integer((Xd-DragOX) Div 10*10);
      Obj[DrgObj].Y:=Integer((Yd-DragOY) Div 10*10);
      Modified:=True;NeedDraw:=True;
     End;
  3,4: If PageAtPoint(X,Y,Pg,Xd,Yd) Then Begin
      If Pg=Obj[DrgObj].Pg Then Begin
       Obj[DrgObj].W:=Integer(Max2(30,Xd-Obj[DrgObj].X));
       Obj[DrgObj].H:=Integer(Max2(20,Yd-Obj[DrgObj].Y));
       Modified:=True;NeedDraw:=True;
      End;
     End;
  5: VThumb(Y);
  6: HThumb(X);
 End;
End;

Procedure MouseUp(X,Y: LongInt);
Begin
 If (Dragging=2) And InBox(X,Y,0,352,40,396) Then Begin
  DeleteObject(DrgObj);
 End;
 If Dragging=4 Then Begin
  If (Obj[DrgObj].W<=20) And (Obj[DrgObj].H<=20) Then Begin
   Obj[DrgObj].W:=700;Obj[DrgObj].H:=300;
  End;
  Tool:=TL_SEL;
  Relayout;
 End;
 If Dragging=3 Then Relayout;
 If (Dragging=1) And (SelA=Cur) Then SelA:=-1;
 Dragging:=0;
 NeedDraw:=True;
End;

{ ====================================================================== }
{                      ECRAN D'ACCUEIL, INITIALISATION                   }
{ ====================================================================== }

Procedure BigText(X,Y,H: Integer; Const S: String; At: Byte);
Var I,W: Integer;
Begin
 For I:=1 To Length(S) Do Begin
  DrawGlyph(Ord(S[I]),X,Y,H,At,INK);
  W:=A16[Ord(S[I])]*H*5 Div 128;
  If (At And A_BOLD)<>0 Then W:=W+H Div 14+1;
  X:=X+W;
 End;
End;

Function BigWidth(Const S: String; H: Integer; At: Byte): Integer;
Var I,W,T: Integer;
Begin
 T:=0;
 For I:=1 To Length(S) Do Begin
  W:=A16[Ord(S[I])]*H*5 Div 128;
  If (At And A_BOLD)<>0 Then W:=W+H Div 14+1;
  T:=T+W;
 End;
 BigWidth:=T;
End;

Procedure ShowSplash;
Var X1,Y1,X2,Y2,I,K: Integer; E: TEvent; T0: LongInt; S: String;
Begin
 CX1:=0;CY1:=0;CX2:=SCR_W-1;CY2:=SCR_H-1;
 FrX:=0;FrY:=0;FrW:=SCR_W;FrH:=SCR_H;RgAng:=0;RgOX:=0;RgOY:=0;
 LastFill:=-1;
 PatBar(0,0,SCR_W-1,SCR_H-1,PatChecker);
 X1:=100;Y1:=60;X2:=540;Y2:=400;
 Box(X1+5,Y1+5,X2+5,Y2+5,INK);
 Box(X1,Y1,X2,Y2,PAPER);
 Frame(X1,Y1,X2,Y2);Frame(X1+3,Y1+3,X2-3,Y2-3);
 { roseaux }
 SetColor(INK);
 For K:=0 To 4 Do Begin
  Line(250+K*30,250,230+K*40,130+Abs(K-2)*20);
  Line(251+K*30,250,231+K*40,130+Abs(K-2)*20);
  SetFill(INK);LastFill:=-1;
  FillEllipse(230+K*40,124+Abs(K-2)*20,7,18);
 End;
 For K:=0 To 6 Do Line(210+K*6,262+K*3,430-K*6,262+K*3);
 S:='papyrus';
 BigText((X1+X2-BigWidth(S,64,A_BOLD Or A_ITAL)) Div 2,270,64,S,A_BOLD Or A_ITAL);
 S:='Traitement de texte multilingue';
 BigText((X1+X2-BigWidth(S,16,0)) Div 2,345,16,S,0);
 S:='Version '+VERSION_TEXT+' - OFFICE-0';
 PText((X1+X2-TextW(S)) Div 2,372,S);
 T0:=Tick;
 Repeat
  PollEvent(E);
 Until (E.Kind=1) Or (E.Kind=2) Or (Abs(Tick-T0)>250);
End;

Procedure InitData;
Var I: Integer;
Begin
 FillChar(St,SizeOf(St),0);
 FillChar(Obj,SizeOf(Obj),0);
 NObj:=0;
 AllocStory(0,MAINCAP,MAINPAR);
 AllocStory(1,HFCAP,HFPAR);
 AllocStory(2,HFCAP,HFPAR);
 GetMem(ML,SizeOf(TLineArr));
 GetMem(TLn,(TMPLN+1)*SizeOf(TLine));
 ClipT:=Nil;ClipA:=Nil;ClipF:=Nil;ClipN:=0;
 UndoT:=Nil;UndoA:=Nil;UndoF:=Nil;UndoPa:=Nil;UndoOK:=False;
 DefaultConfig;DefaultFmts;DefaultFKeys;
 Zoom:=100;ScrX:=0;ScrY:=0;
 ToolsOn:=True;RulerOn:=True;FormatOn:=True;GuidesOn:=True;Preview:=False;FullWin:=False;
 Tool:=TL_TEXT;SelObj:=0;TabKind:=0;
 ASt:=0;Cur:=0;SelA:=-1;CurPg:=1;TypA:=0;TypF:=DEFF;MarkMode:=False;
 Quit:=False;NeedDraw:=True;Dragging:=0;MenuOpen:=0;MenuHi:=0;
 LayoutOK:=False;NML:=0;NTL:=0;NPages:=1;WantX:=-1;LastTyping:=False;
 DocName:='';Named:=False;Modified:=False;
 FindStr:='';ReplStr:='';FindCase:=False;PrintDest:='PRN';
 MX:=0;MY:=0;MB:=0;LastB:=0;LastClickT:=0;LastFill:=-1;
 CaretOn:=False;NoSel:=False;DrawPage:=1;
End;

Procedure ShowHelpLine;
Begin
 WriteLn('PAPYRUS - Clone graphique du traitement de texte Papyrus (Atari ST).');
 WriteLn;
 WriteLn('Utilisation : PAPYRUS [fichier.PAP] [/?]');
 WriteLn;
 WriteLn('  fichier.PAP  Document a ouvrir.');
 WriteLn('  /?           Affiche cette aide.');
 WriteLn;
 WriteLn('Langue par defaut : francais. Menus a la souris ; Alt+lettre ouvre un menu.');
End;

Procedure MainLoop;
Var E: TEvent; T: LongInt;
Begin
 Repeat
  If NeedDraw Then DrawAll;
  PollEvent(E);
  Case E.Kind Of
   1: HandleKey(E.Key);
   2: MouseDown(E.X,E.Y);
   3: MouseUp(E.X,E.Y);
   4: MouseMove(E.X,E.Y);
   0: Begin
       T:=Tick;
       If (T<CaretT) Or (T-CaretT>=50) Then Begin
        HideMouse;ToggleCaret;ShowMouse;CaretT:=T;
       End;
      End;
  End;
 Until Quit;
End;

BEGIN
 If (ParamCount>=1) And ((ParamStr(1)='/?') Or (ParamStr(1)='-h') Or
    (ParamStr(1)='--help')) Then Begin
  ShowHelpLine;
  Halt(0);
 End;
 InitData;
 LoadConfig;
 InitializeGraphics;
 BuildFont;
 If MouseDriverFound Then ShowMouse;
 ShowSplash;
 If (ParamCount>=1) And FileExists(AddExt(ParamStr(1),'PAP')) Then Begin
  If Not LoadPAP(AddExt(ParamStr(1),'PAP')) Then MakeDemo;
 End Else MakeDemo;
 CalcGeo;
 MainLoop;
 CloseGraph;
END.
