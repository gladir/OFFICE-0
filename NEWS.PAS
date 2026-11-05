{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/office-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
  @description: Clone de l'application News Master (publication de journaux)
}

Program NEWS;

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
 SCR_W    = 640;
 SCR_H    = 480;
 MENU_H   = 18;
 INK      = 0;
 PAPER    = 15;
 PANEL_Y  = 380;        { haut du panneau de touches de fonction }
 TBH      = 20;         { hauteur de la barre de titre des dialogues }
 NMENU    = 8;
 VW       = 640;        { zone d'affichage des pages }
 VH       = 361;

 { Page (en points a l'echelle 1:1) }
 PGW      = 800;
 PGH      = 1040;
 PGGAP    = 16;
 MAXPG    = 8;
 MAXCOL   = 4;
 MRG      = 40;
 HEADH    = 170;
 COLGAP   = 16;
 MINSLOT  = 60;
 PAD      = 6;

 MAXFONT  = 40;
 MAXLINE  = 900;
 MAXREG   = 32;
 MAXART   = 48;
 MAXLIB   = 16;
 STCAP    = 12000;
 HCAP     = 240;
 CLIPCAP  = 6000;
 MAXCTL   = 24;

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

 { Habillage du texte autour des objets }
 FL_OVER  = 0;
 FL_BOTH  = 1;
 FL_LEFT  = 2;
 FL_RIGHT = 3;
 FL_CLEAR = 4;

 { Types d'objets }
 AR_ART   = 1;
 AR_LINE  = 2;
 AR_BOX   = 3;

 { Modes d'edition (menu courant du panneau) }
 MD_MAIN   = 0;
 MD_VIEW   = 1;
 MD_TEXT   = 2;
 MD_ART    = 3;
 MD_LAYOUT = 4;
 MD_FILE   = 5;
 MD_PRINT  = 6;

 { Alignement des paragraphes }
 AL_LEFT   = 0;
 AL_RIGHT  = 1;
 AL_CENTER = 2;
 AL_BOTH   = 3;

{ ====================================================================== }
{                                TYPES                                   }
{ ====================================================================== }

Type
 TBytes = Array[0..65000] Of Byte;
 PBytes = ^TBytes;
 TWords = Array[0..255] Of Word;
 PWords = ^TWords;

 TStory = Record
  Len,Cap : Integer;
  T,F,A   : PBytes;       { caracteres, polices, alignement (sur les CR) }
 End;

 TLine = Record
  S,E,Nx   : Integer;     { debut, fin (exclue), debut de la ligne suivante }
  X,Y,W,H  : Integer;     { emplacement sur la page (points) }
  Asc,Lw   : Integer;     { ligne de base, largeur naturelle }
  Ns       : Integer;     { nombre d'espaces }
  Sty,Pg,Al,Fl : Byte;    { histoire, page, alignement, 1 = fin de paragraphe }
 End;
 TLineArr = Array[0..MAXLINE] Of TLine;
 PLineArr = ^TLineArr;

 TPiece = Record
  Name : String[16];
  W,H  : Integer;
  B    : PBytes;          { bitmap monochrome, (W+7) div 8 octets par rangee }
 End;

 TArt = Record
  Kind,Flow,FH,FV,Pat,Th : Byte;
  Lib    : Integer;
  Pg     : Integer;
  X,Y,W,H : Integer;      { page, points }
  X2,Y2  : Integer;       { extremite d'une ligne }
  SX1,SY1,SX2,SY2 : Integer; { zone source (rognage) }
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

 TPBtn = Record
  Fk    : Byte;
  L1,L2,L3 : String[10];
  Ico   : Byte;
  On    : Boolean;
 End;

{ ====================================================================== }
{                              VARIABLES                                 }
{ ====================================================================== }

Var
 { Document }
 St        : Array[0..MAXPG] Of TStory;
 NPg       : Integer;
 NCol      : Array[1..MAXPG] Of Byte;
 HasHead   : Array[1..MAXPG] Of Boolean;
 Arts      : Array[1..MAXART] Of TArt;
 NArt      : Integer;
 DocName   : String[79];
 Named,Modified : Boolean;

 { Polices }
 NFont     : Integer;
 FName     : Array[0..MAXFONT-1] Of String[26];
 FAsc,FDsc,FSpc,FGap,FKind : Array[0..MAXFONT-1] Of Integer;
 FPos,FLen : Array[0..MAXFONT-1] Of LongInt;
 FSys      : Array[0..MAXFONT-1] Of Byte;
 FBuf      : Array[0..MAXFONT-1] Of PBytes;
 FOff      : Array[0..MAXFONT-1] Of PWords;
 FAdv      : Array[0..MAXFONT-1] Of PBytes;
 FLBFile   : String[79];
 FLBFound,UseFLB : Boolean;
 DefBody,DefHead : Integer;
 G8        : Array[0..255,0..7] Of Byte;

 { Bibliotheque d'images }
 Lib       : Array[1..MAXLIB] Of TPiece;
 NLib      : Integer;

 { Mise en page calculee }
 Lines     : PLineArr;
 NLn       : Integer;
 Overflow  : Boolean;
 NReg      : Integer;
 RegPg,RegX,RegY,RegW,RegH : Array[1..MAXREG] Of Integer;

 { Edition du texte }
 ASt       : Integer;          { histoire active }
 Cur,SelA  : Integer;
 CurFont   : Integer;
 MarkMode  : Boolean;
 WantX     : Integer;
 TypRun    : Boolean;
 ClipT,ClipF : PBytes;
 ClipN     : Integer;
 UndoT,UndoF,UndoA : PBytes;
 UndoLen,UndoCur,UndoSt : Integer;
 UndoOK    : Boolean;
 FindStr   : String[40];
 Lang      : Integer;          { 0 francais, 1 anglais, 2 allemand }

 { Edition des images }
 ACx,ACy   : LongInt;          { curseur d'images (coordonnees document) }
 ACStep    : Integer;
 SelArt    : Integer;
 Held      : TArt;
 HeldOn    : Boolean;
 ArtSub    : Integer;          { 0 normal, 1 taille, 2 rogner, 3 trace }
 CropEnd   : Integer;
 DrawKind  : Integer;
 DrawPat   : Integer;
 DrawTh    : Integer;
 DrawStep  : Integer;          { 0 hors tracage, 1 point de depart pose }
 DrawX0,DrawY0 : LongInt;
 LastPiece : Integer;

 { Affichage }
 Mode      : Integer;
 ZN,ZD     : Integer;          { echelle = ZN/ZD }
 ViewNo    : Integer;
 ScrX,ScrY : LongInt;
 GuidesOn  : Boolean;
 CurPage   : Integer;          { page courante (mise en page) }
 PB        : Array[1..10] Of TPBtn;
 NPB       : Integer;
 PanelTitle : String[40];
 PBDown    : Integer;

 { Souris / evenements }
 MX,MY,MB,LastB : LongInt;
 PrevMX,PrevMY  : LongInt;
 Quit,NeedDraw  : Boolean;
 MenuOpen,MenuHi : Integer;
 Dragging  : Integer;
 DragOX,DragOY : LongInt;
 CaretOn   : Boolean;
 CaretT    : LongInt;
 LastClickT : LongInt;
 LastFill  : Integer;
 StatusMsg : String[60];
 StatusT   : LongInt;

 { Dialogues }
 DC        : Array[1..MAXCTL] Of TCtl;
 NDC       : Integer;
 DlgX,DlgY,DlgW,DlgH,DlgFocus,DlgId : Integer;
 DlgFresh  : Boolean;
 DlgTitle  : String[44];

Const
 C_LABEL  = 1;
 C_EDIT   = 2;
 C_CHECK  = 3;
 C_RADIO  = 4;
 C_BTN    = 5;
 C_POP    = 6;
 C_GROUP  = 7;

 PatStripe : FillPatternType = ($88,$88,$88,$88,$88,$88,$88,$88);
 PatGrey   : FillPatternType = ($AA,$55,$AA,$55,$AA,$55,$AA,$55);
 PatLight  : FillPatternType = ($88,$00,$22,$00,$88,$00,$22,$00);
 PatDark   : FillPatternType = ($EE,$BB,$EE,$BB,$EE,$BB,$EE,$BB);
 PatHatch  : FillPatternType = ($88,$44,$22,$11,$88,$44,$22,$11);
 PatHatch2 : FillPatternType = ($11,$22,$44,$88,$11,$22,$44,$88);
 PatHoriz  : FillPatternType = ($FF,$00,$00,$00,$FF,$00,$00,$00);
 PatVert   : FillPatternType = ($88,$88,$88,$88,$88,$88,$88,$88);
 PatGrid   : FillPatternType = ($FF,$88,$88,$88,$FF,$88,$88,$88);
 PatBrick  : FillPatternType = ($FF,$80,$80,$80,$FF,$08,$08,$08);
 PatDots   : FillPatternType = ($80,$00,$08,$00,$80,$00,$08,$00);
 NPAT      = 12;

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

Function Clamp(V,Lo,Hi: LongInt): LongInt;
Begin
 If V<Lo Then V:=Lo;
 If V>Hi Then V:=Hi;
 Clamp:=V;
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

Function NoExt(Const N: String): String;
Var I: Integer;
Begin
 I:=Length(N);
 While (I>0) And (N[I]<>'.') And (N[I]<>'\') And (N[I]<>'/') Do Dec(I);
 If (I>0) And (N[I]='.') Then NoExt:=Copy(N,1,I-1) Else NoExt:=N;
End;

Function Tick: LongInt;
Var H,M,S,S100: Word;
Begin
 GetTime(H,M,S,S100);
 Tick:=((LongInt(H)*60+M)*60+S)*100+S100;
End;

Function InBox(X,Y,X1,Y1,X2,Y2: LongInt): Boolean;
Begin
 InBox:=(X>=X1) And (X<=X2) And (Y>=Y1) And (Y<=Y2);
End;

Function HeapOK(Sz: LongInt): Boolean;
Begin
 {$IFDEF FPC}
 HeapOK:=True;
 {$ELSE}
 HeapOK:=MaxAvail>=Sz;
 {$ENDIF}
End;

Function Tr(Const S: String): String; Forward;

Procedure SetStatus(Const S: String);
Begin
 StatusMsg:=Tr(S);
 StatusT:=Tick;
 NeedDraw:=True;
End;

{ ====================================================================== }
{                       PRIMITIVES GRAPHIQUES (GUI)                      }
{ ====================================================================== }

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

{ Boite ombree avec texte centre (etiquette du panneau) }
Procedure LabelBox(X1,Y1,X2,Y2: Integer; Const S: String);
Begin
 Box(X1+3,Y1+3,X2+3,Y2+3,INK);
 Box(X1,Y1,X2,Y2,PAPER);
 Frame(X1,Y1,X2,Y2);
 Frame(X1+1,Y1+1,X2-1,Y2-1);
 BText((X1+X2+1-TextW(S)) Div 2,(Y1+Y2-6) Div 2,S);
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
Procedure Button(X1,Y1,X2,Y2: Integer; Const S0: String; Def,Enabled: Boolean);
Var TX: Integer; S: String;
Begin
 S:=Tr(S0);
 Box(X1,Y1,X2,Y2,PAPER);
 Frame(X1,Y1,X2,Y2);
 If Def Then Begin Frame(X1+1,Y1+1,X2-1,Y2-1);Frame(X1-1,Y1-1,X2+1,Y2+1);End;
 TX:=(X1+X2+1-TextW(S)) Div 2;
 If Enabled Then UText(TX,(Y1+Y2-6) Div 2,S,INK)
 Else GreyText(TX,(Y1+Y2-6) Div 2,S);
End;

{ ====================================================================== }
{                  EVENEMENTS (clavier / souris)                         }
{ ====================================================================== }

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

Function TrEN(Const S: String): String;
Begin
 TrEN:='';
 If S='NEWSMASTER - CLONE VERSION ' Then Begin
   TrEN:='NEWSMASTER - CLONE VERSION ';Exit;End;
 If S='PROGRAMME DE PUBLICATION DE JOURNAUX' Then Begin
   TrEN:='NEWSLETTER PUBLISHING PROGRAM';Exit;End;
 If S='D''APRES NEWS MASTER (UNISON WORLD, 1986)' Then Begin
   TrEN:='BASED ON NEWS MASTER (UNISON WORLD, 1986)';Exit;End;
 If S='APPUYEZ SUR ESPACE POUR CONTINUER' Then Begin
   TrEN:='PRESS SPACE TO CONTINUE';Exit;End;
 If S='NewsMaster : Menu principal' Then Begin TrEN:='NewsMaster: Main Menu';
   Exit;End;
 If S='Choisissez une activit'#130' :' Then Begin TrEN:='Choose an activity:';
   Exit;End;
 If S='Commencer un nouveau journal' Then Begin
   TrEN:='Start work on a new newsletter';Exit;End;
 If S='Continuer le journal courant' Then Begin
   TrEN:='Continue working on the current newsletter';Exit;End;
 If S='Choisir un journal enregistr'#130 Then Begin
   TrEN:='Select a saved newsletter to work on';Exit;End;
 If S='Quitter NewsMaster' Then Begin TrEN:='Quit NewsMaster';Exit;End;
 If S='ENTR'#144'E : POINT FINAL' Then Begin TrEN:='ENTER: END POINT';Exit;End;
 If S='OBJET AJOUT'#144 Then Begin TrEN:='OBJECT ADDED';Exit;End;
 If S='Clone graphique du programme de publication de journaux News Master.'
   Then Begin
   TrEN:='Graphical clone of the News Master newsletter publishing program.';
   Exit;End;
 If S='Utilisation : NEWS [fichier.NWC] [/?]' Then Begin
   TrEN:='Usage: NEWS [file.NWC] [/?]';Exit;End;
 If S='fichier.NWC  Journal '#133' ouvrir.' Then Begin
   TrEN:='file.NWC     Newsletter to open.';Exit;End;
 If S='/?           Affiche cette aide.' Then Begin
   TrEN:='/?           Show this help.';Exit;End;
 If S='Langue : fran'#135'ais par d'#130'faut. LANGUAGE=EN : anglais, '+
   'LANGUAGE=GR : allemand.' Then Begin
   TrEN:='Language: French by default. LANGUAGE=EN: English, LANGUAGE=GR: '+
   'German.';Exit;End;
 If S='Place NEWS.FLB dans le r'#130'pertoire courant pour utiliser les '+
   'polices originales.' Then Begin
   TrEN:='Put NEWS.FLB in the current directory to use the original fonts.';
   Exit;End;
 If S='Couverts' Then Begin TrEN:='Cutlery';Exit;End;
 If S='Poisson' Then Begin TrEN:='Fish';Exit;End;
 If S='Etoile' Then Begin TrEN:='Star';Exit;End;
 If S='Soleil' Then Begin TrEN:='Sun';Exit;End;
 If S='Maison' Then Begin TrEN:='House';Exit;End;
 If S='Arbre' Then Begin TrEN:='Tree';Exit;End;
 If S='Ciseaux' Then Begin TrEN:='Scissors';Exit;End;
 If S='Ballon' Then Begin TrEN:='Balloon';Exit;End;
 If S='Telephone' Then Begin TrEN:='Telephone';Exit;End;
 If S='Coeur' Then Begin TrEN:='Heart';Exit;End;
 If S='Fleche' Then Begin TrEN:='Arrow';Exit;End;
 If S='Journal' Then Begin TrEN:='Newspaper';Exit;End;
 If S='Tasse' Then Begin TrEN:='Cup';Exit;End;
 If S='Livre' Then Begin TrEN:='Book';Exit;End;
 If S='Gauche' Then Begin TrEN:='Left';Exit;End;
 If S='Droite' Then Begin TrEN:='Right';Exit;End;
 If S='Centr'#130 Then Begin TrEN:='Centered';Exit;End;
 If S='Justifi'#130 Then Begin TrEN:='Justified';Exit;End;
 If S='Texte par-dessus' Then Begin TrEN:='Text over art';Exit;End;
 If S='Texte des deux c'#147't'#130's' Then Begin TrEN:='Text on both sides';
   Exit;End;
 If S='Texte '#133' gauche seul' Then Begin TrEN:='Text on left only';Exit;End;
 If S='Texte '#133' droite seul' Then Begin TrEN:='Text on right only';Exit;End;
 If S='Zone d'#130'gag'#130'e' Then Begin TrEN:='Keep clear';Exit;End;
 If S='Grand pas (16)' Then Begin TrEN:='Big step (16)';Exit;End;
 If S='Pas moyen (4)' Then Begin TrEN:='Medium step (4)';Exit;End;
 If S='Un point (1)' Then Begin TrEN:='One dot (1)';Exit;End;
 If S='Ligne' Then Begin TrEN:='Line';Exit;End;
 If S='Bo'#140'te' Then Begin TrEN:='Box';Exit;End;
 If S='Horizontalement' Then Begin TrEN:='Horizontally';Exit;End;
 If S='Verticalement' Then Begin TrEN:='Vertically';Exit;End;
 If S='&Oui' Then Begin TrEN:='&Yes';Exit;End;
 If S='&Non' Then Begin TrEN:='&No';Exit;End;
 If S='&Annuler' Then Begin TrEN:='&Cancel';Exit;End;
 If S='Fichier' Then Begin TrEN:='File';Exit;End;
 If S='Edition' Then Begin TrEN:='Edit';Exit;End;
 If S='Texte' Then Begin TrEN:='Text';Exit;End;
 If S='Image' Then Begin TrEN:='Artwork';Exit;End;
 If S='Page' Then Begin TrEN:='Page';Exit;End;
 If S='Vue' Then Begin TrEN:='View';Exit;End;
 If S='Options' Then Begin TrEN:='Options';Exit;End;
 If S=#192' propos de NewsMaster...' Then Begin TrEN:='About NewsMaster...';
   Exit;End;
 If S='Statistiques...' Then Begin TrEN:='Statistics...';Exit;End;
 If S='M'#130'moire libre' Then Begin TrEN:='Free memory';Exit;End;
 If S='Menu principal...' Then Begin TrEN:='Main menu...';Exit;End;
 If S='Nouveau|^N' Then Begin TrEN:='New|^N';Exit;End;
 If S='Ouvrir...|^O' Then Begin TrEN:='Open...|^O';Exit;End;
 If S='Enregistrer|^S' Then Begin TrEN:='Save|^S';Exit;End;
 If S='Enregistrer sous...' Then Begin TrEN:='Save as...';Exit;End;
 If S='Importer texte ASCII...' Then Begin TrEN:='Import ASCII text...';Exit;
   End;
 If S='Exporter texte ASCII...' Then Begin TrEN:='Export ASCII text...';Exit;
   End;
 If S='Imprimer la page (PBM)...' Then Begin TrEN:='Print page (PBM)...';Exit;
   End;
 If S='Imprimer tout (PBM)...' Then Begin TrEN:='Print all (PBM)...';Exit;End;
 If S='Quitter|^Q' Then Begin TrEN:='Quit|^Q';Exit;End;
 If S='Annuler|^Z' Then Begin TrEN:='Undo|^Z';Exit;End;
 If S='Couper|^X' Then Begin TrEN:='Cut|^X';Exit;End;
 If S='Copier|^C' Then Begin TrEN:='Copy|^C';Exit;End;
 If S='Coller|^V' Then Begin TrEN:='Paste|^V';Exit;End;
 If S='Effacer|Suppr' Then Begin TrEN:='Clear|Del';Exit;End;
 If S='Tout s'#130'lectionner|^A' Then Begin TrEN:='Select all|^A';Exit;End;
 If S='Chercher...|^F' Then Begin TrEN:='Find...|^F';Exit;End;
 If S='Chercher suivant|^G' Then Begin TrEN:='Find next|^G';Exit;End;
 If S='Choisir la police...|^T' Then Begin TrEN:='Choose font...|^T';Exit;End;
 If S='Police pr'#130'c'#130'dente' Then Begin TrEN:='Previous font';Exit;End;
 If S='Police suivante' Then Begin TrEN:='Next font';Exit;End;
 If S='Aligner '#133' gauche|^L' Then Begin TrEN:='Align left|^L';Exit;End;
 If S='Aligner '#133' droite|^R' Then Begin TrEN:='Align right|^R';Exit;End;
 If S='Centrer|^E' Then Begin TrEN:='Center|^E';Exit;End;
 If S='Justifier|^J' Then Begin TrEN:='Justify|^J';Exit;End;
 If S='Marquer la s'#130'lection' Then Begin TrEN:='Mark selection';Exit;End;
 If S='Mode '#130'dition du texte|F2' Then Begin TrEN:='Text edit mode|F2';Exit;
   End;
 If S='Mode '#130'dition d''images|F3' Then Begin TrEN:='Artwork edit mode|F3';
   Exit;End;
 If S='Choisir une image...|F1' Then Begin TrEN:='Choose artwork...|F1';Exit;
   End;
 If S='Prendre|F2' Then Begin TrEN:='Pick up|F2';Exit;End;
 If S='Prendre une copie|F3' Then Begin TrEN:='Pick up a copy|F3';Exit;End;
 If S='Poser|Entr'#130'e' Then Begin TrEN:='Stamp down|Enter';Exit;End;
 If S='Supprimer|Suppr' Then Begin TrEN:='Delete|Del';Exit;End;
 If S='Agrandir|+' Then Begin TrEN:='Enlarge|+';Exit;End;
 If S='R'#130'duire|-' Then Begin TrEN:='Shrink|-';Exit;End;
 If S='Taille d''origine' Then Begin TrEN:='Original size';Exit;End;
 If S='Retourner horizontal.' Then Begin TrEN:='Flip horizontally';Exit;End;
 If S='Retourner vertical.' Then Begin TrEN:='Flip vertically';Exit;End;
 If S='Tracer une ligne' Then Begin TrEN:='Draw a line';Exit;End;
 If S='Tracer une bo'#140'te' Then Begin TrEN:='Draw a box';Exit;End;
 If S='Motif de remplissage...' Then Begin TrEN:='Fill pattern...';Exit;End;
 If S=#144'paisseur du trait...' Then Begin TrEN:='Line thickness...';Exit;End;
 If S='Mode mise en page|F4' Then Begin TrEN:='Page layout mode|F4';Exit;End;
 If S='Ajouter une colonne' Then Begin TrEN:='Add a column';Exit;End;
 If S='Supprimer une colonne' Then Begin TrEN:='Delete a column';Exit;End;
 If S='Ajouter un titre' Then Begin TrEN:='Add a headline';Exit;End;
 If S='Supprimer le titre' Then Begin TrEN:='Delete the headline';Exit;End;
 If S='Ajouter une page' Then Begin TrEN:='Add a page';Exit;End;
 If S='Supprimer la page' Then Begin TrEN:='Delete the page';Exit;End;
 If S='Page pr'#130'c'#130'dente|PgHaut' Then Begin TrEN:='Previous page|PgUp';
   Exit;End;
 If S='Page suivante|PgBas' Then Begin TrEN:='Next page|PgDn';Exit;End;
 If S=#133' la page...' Then Begin TrEN:='Go to page...';Exit;End;
 If S='Zoom avant (x2)' Then Begin TrEN:='Zoom in (x2)';Exit;End;
 If S='Vue normale' Then Begin TrEN:='Normal view';Exit;End;
 If S='Largeur de la page' Then Begin TrEN:='Page width';Exit;End;
 If S='Page enti'#138're' Then Begin TrEN:='Whole page';Exit;End;
 If S='Pas du curseur : grand' Then Begin TrEN:='Cursor step: big';Exit;End;
 If S='Pas du curseur : moyen' Then Begin TrEN:='Cursor step: medium';Exit;End;
 If S='Pas du curseur : point' Then Begin TrEN:='Cursor step: dot';Exit;End;
 If S='Polices de NEWS.FLB' Then Begin TrEN:='Fonts from NEWS.FLB';Exit;End;
 If S='Guides de colonnes' Then Begin TrEN:='Column guides';Exit;End;
 If S='Afficher les infos...' Then Begin TrEN:='About...';Exit;End;
 If S='MENU D'''#144'DITION PRINCIPAL' Then Begin TrEN:='MAIN EDIT MENU';Exit;
   End;
 If S='VUE' Then Begin TrEN:='VIEW';Exit;End;
 If S='TEXTE' Then Begin TrEN:='TEXT';Exit;End;
 If S='IMAGES' Then Begin TrEN:='ART';Exit;End;
 If S='PAGE' Then Begin TrEN:='PAGE';Exit;End;
 If S='FICHIER' Then Begin TrEN:='FILE';Exit;End;
 If S='IMPRIM.' Then Begin TrEN:='PRINT';Exit;End;
 If S='CHANGER LA VUE DU JOURNAL' Then Begin TrEN:='CHANGE THE PAGE VIEW';Exit;
   End;
 If S='ZOOM|AVANT' Then Begin TrEN:='ZOOM|IN';Exit;End;
 If S='VUE|NORMALE' Then Begin TrEN:='NORMAL|VIEW';Exit;End;
 If S='LARGEUR|DE PAGE' Then Begin TrEN:='PAGE|WIDTH';Exit;End;
 If S='PAGE|ENTI'#138'RE' Then Begin TrEN:='WHOLE|PAGE';Exit;End;
 If S='PAGE|PR'#144'C.' Then Begin TrEN:='PREV.|PAGE';Exit;End;
 If S='PAGE|SUIV.' Then Begin TrEN:='NEXT|PAGE';Exit;End;
 If S='MODIFIER LE TEXTE' Then Begin TrEN:='EDIT TEXT';Exit;End;
 If S='CHOISIR|POLICE' Then Begin TrEN:='CHOOSE|FONT';Exit;End;
 If S='ALIGNE-|MENT' Then Begin TrEN:='ALIGN-|MENT';Exit;End;
 If S='S'#144'LEC-|TION' Then Begin TrEN:='SELECT';Exit;End;
 If S='COUPER' Then Begin TrEN:='CUT';Exit;End;
 If S='COPIER' Then Begin TrEN:='COPY';Exit;End;
 If S='COLLER' Then Begin TrEN:='PASTE';Exit;End;
 If S='IMPORT|ASCII' Then Begin TrEN:='IMPORT|ASCII';Exit;End;
 If S='ANNULER' Then Begin TrEN:='UNDO';Exit;End;
 If S='MODIFIER LES IMAGES' Then Begin TrEN:='EDIT ARTWORK';Exit;End;
 If S='CHOISIR|IMAGE' Then Begin TrEN:='CHOOSE|ART';Exit;End;
 If S='PRENDRE' Then Begin TrEN:='PICK UP';Exit;End;
 If S='PRENDRE|COPIE' Then Begin TrEN:='PICK UP|COPY';Exit;End;
 If S='POSER' Then Begin TrEN:='STAMP';Exit;End;
 If S='TAILLE' Then Begin TrEN:='SIZE';Exit;End;
 If S='ROGNER' Then Begin TrEN:='CROP';Exit;End;
 If S='HABIL-|LAGE' Then Begin TrEN:='TEXT|FLOW';Exit;End;
 If S='RETOUR-|NER' Then Begin TrEN:='FLIP';Exit;End;
 If S='LIGNE|BO'#139'TE' Then Begin TrEN:='LINE|BOX';Exit;End;
 If S='SUPPR.' Then Begin TrEN:='DELETE';Exit;End;
 If S='MODIFIER LA MISE EN PAGE' Then Begin TrEN:='EDIT THE PAGE LAYOUT';Exit;
   End;
 If S='AJOUT|COLONNE' Then Begin TrEN:='ADD|COLUMN';Exit;End;
 If S='SUPPR.|COLONNE' Then Begin TrEN:='DELETE|COLUMN';Exit;End;
 If S='AJOUT|TITRE' Then Begin TrEN:='ADD|HEAD|LINE';Exit;End;
 If S='SUPPR.|TITRE' Then Begin TrEN:='DELETE|HEAD|LINE';Exit;End;
 If S='AJOUT|PAGE' Then Begin TrEN:='ADD|PAGE';Exit;End;
 If S='SUPPR.|PAGE' Then Begin TrEN:='DELETE|PAGE';Exit;End;
 If S='CHARGER ET ENREGISTRER' Then Begin TrEN:='LOAD AND SAVE NEWSLETTER';Exit;
   End;
 If S='NOUVEAU' Then Begin TrEN:='NEW';Exit;End;
 If S='OUVRIR' Then Begin TrEN:='LOAD';Exit;End;
 If S='ENREG.' Then Begin TrEN:='SAVE';Exit;End;
 If S='ENREG.|SOUS' Then Begin TrEN:='SAVE|AS';Exit;End;
 If S='MENU|PRINC.' Then Begin TrEN:='MAIN|MENU';Exit;End;
 If S='QUITTER' Then Begin TrEN:='QUIT';Exit;End;
 If S='IMPRIMER LE JOURNAL' Then Begin TrEN:='PRINT NEWSLETTER';Exit;End;
 If S='CETTE|PAGE' Then Begin TrEN:='THIS|PAGE';Exit;End;
 If S='TOUTES|PAGES' Then Begin TrEN:='ALL|PAGES';Exit;End;
 If S='EXPORT|TEXTE' Then Begin TrEN:='EXPORT|TEXT';Exit;End;
 If S='ZOOM X2' Then Begin TrEN:='ZOOM X2';Exit;End;
 If S='NORMALE' Then Begin TrEN:='NORMAL';Exit;End;
 If S='LARGEUR' Then Begin TrEN:='WIDTH';Exit;End;
 If S='PAGE ENTI'#138'RE' Then Begin TrEN:='WHOLE PAGE';Exit;End;
 If S='PAS ' Then Begin TrEN:='STEP ';Exit;End;
 If S='ROGNAGE' Then Begin TrEN:='CROP';Exit;End;
 If S='TRAC'#144 Then Begin TrEN:='DRAW';Exit;End;
 If S='SANS NOM' Then Begin TrEN:='UNNAMED';Exit;End;
 If S='PAGE ' Then Begin TrEN:='PAGE ';Exit;End;
 If S='TEXTE EN TROP' Then Begin TrEN:='TEXT OVERFLOW';Exit;End;
 If S='MISE EN PAGE - PAGE ' Then Begin TrEN:='PAGE LAYOUT - PAGE ';Exit;End;
 If S=' COLONNES' Then Begin TrEN:=' COLUMNS';Exit;End;
 If S=' COLONNE' Then Begin TrEN:=' COLUMN';Exit;End;
 If S=' + TITRE' Then Begin TrEN:=' + HEADLINE';Exit;End;
 If S='TEXTE TROP LONG' Then Begin TrEN:='TEXT TOO LONG';Exit;End;
 If S=' CARACT'#138'RES COPI'#144'S' Then Begin TrEN:=' CHARACTERS COPIED';Exit;
   End;
 If S='MARQUEZ AVEC LES FL'#138'CHES' Then Begin
   TrEN:='MARK WITH THE ARROW KEYS';Exit;End;
 If S='S'#144'LECTION FIX'#144'E' Then Begin TrEN:='SELECTION FIXED';Exit;End;
 If S='Choisir une police' Then Begin TrEN:='Choose Font';Exit;End;
 If S=' polices' Then Begin TrEN:=' fonts';Exit;End;
 If S='int'#130'gr'#130'es' Then Begin TrEN:='built-in';Exit;End;
 If S='INTROUVABLE' Then Begin TrEN:='NOT FOUND';Exit;End;
 If S='Chercher' Then Begin TrEN:='Find';Exit;End;
 If S='Texte '#133' chercher :' Then Begin TrEN:='Text to find:';Exit;End;
 If S='TROP D''OBJETS' Then Begin TrEN:='TOO MANY OBJECTS';Exit;End;
 If S='RIEN A POSER' Then Begin TrEN:='NOTHING TO STAMP';Exit;End;
 If S='AUCUNE IMAGE ICI' Then Begin TrEN:='NO ARTWORK HERE';Exit;End;
 If S='Choisir une image' Then Begin TrEN:='Choose Artwork';Exit;End;
 If S='Fl'#138'ches : choisir  Entr'#130'e : valider' Then Begin
   TrEN:='Arrows: choose  Enter: accept';Exit;End;
 If S='M'#138'ME PAGE SVP' Then Begin TrEN:='SAME PAGE PLEASE';Exit;End;
 If S='ENTR'#144'E : POINT DE D'#144'PART' Then Begin
   TrEN:='ENTER: START POINT';Exit;End;
 If S='Motif de remplissage' Then Begin TrEN:='Fill Pattern';Exit;End;
 If S=#144'paisseur' Then Begin TrEN:='Thickness';Exit;End;
 If S='Epaisseur du trait (1-12) :' Then Begin TrEN:='Line thickness (1-12):';
   Exit;End;
 If S='MAXIMUM : ' Then Begin TrEN:='MAXIMUM: ';Exit;End;
 If S='UNE COLONNE MINIMUM' Then Begin TrEN:='AT LEAST ONE COLUMN';Exit;End;
 If S='TITRE D'#144'J'#133' PR'#144'SENT' Then Begin
   TrEN:='HEADLINE ALREADY THERE';Exit;End;
 If S='Titre' Then Begin TrEN:='Headline';Exit;End;
 If S=' PAGES' Then Begin TrEN:=' PAGES';Exit;End;
 If S='IMPOSSIBLE : UNE PAGE' Then Begin TrEN:='IMPOSSIBLE: ONE PAGE ONLY';Exit;
   End;
 If S='TEXTE TRONQU'#144 Then Begin TrEN:='TEXT TRUNCATED';Exit;End;
 If S='Fichier :' Then Begin TrEN:='File:';Exit;End;
 If S='(aucun fichier ' Then Begin TrEN:='(no file ';Exit;End;
 If S='Impression de la page ' Then Begin TrEN:='Printing page ';Exit;End;
 If S='Impression' Then Begin TrEN:='Printing';Exit;End;
 If S='Page ' Then Begin TrEN:='Page ';Exit;End;
 If S=' enregistr'#130'e dans ' Then Begin TrEN:=' saved in ';Exit;End;
 If S='Pages enregistr'#130'es : ' Then Begin TrEN:='Pages saved: ';Exit;End;
 If S='Format : bitmap PBM ' Then Begin TrEN:='Format: PBM bitmap ';Exit;End;
 If S='Erreur d'''#130'criture du fichier.' Then Begin
   TrEN:='File write error.';Exit;End;
 If S='Titre du journal' Then Begin TrEN:='Newsletter headline';Exit;End;
 If S='Les changements non enregistr'#130's seront perdus. Continuer ?' Then
   Begin TrEN:='Unsaved changes will be lost. Continue?';Exit;End;
 If S='Ouvrir un journal' Then Begin TrEN:='Open a Newsletter';Exit;End;
 If S='Ouvrir' Then Begin TrEN:='Open';Exit;End;
 If S='Fichier introuvable : ' Then Begin TrEN:='File not found: ';Exit;End;
 If S='JOURNAL CHARG'#144 Then Begin TrEN:='NEWSLETTER LOADED';Exit;End;
 If S='Ce fichier n''est pas un journal NewsMaster valide.' Then Begin
   TrEN:='This file is not a valid NewsMaster newsletter.';Exit;End;
 If S='Enregistrer le journal' Then Begin TrEN:='Save the Newsletter';Exit;End;
 If S='Enregistrer' Then Begin TrEN:='Save';Exit;End;
 If S='Le fichier ' Then Begin TrEN:='The file ';Exit;End;
 If S=' existe. Le remplacer ?' Then Begin TrEN:=' exists. Replace it?';Exit;
   End;
 If S='JOURNAL ENREGISTR'#144 Then Begin TrEN:='NEWSLETTER SAVED';Exit;End;
 If S='Importer du texte ASCII' Then Begin TrEN:='Import ASCII Text';Exit;End;
 If S='Importer' Then Begin TrEN:='Import';Exit;End;
 If S='Impossible de lire ' Then Begin TrEN:='Cannot read ';Exit;End;
 If S='Exporter le texte ASCII' Then Begin TrEN:='Export ASCII Text';Exit;End;
 If S='TEXTE EXPORT'#144 Then Begin TrEN:='TEXT EXPORTED';Exit;End;
 If S='Exporter' Then Begin TrEN:='Export';Exit;End;
 If S='Quitter NewsMaster ? Les changements seront perdus.' Then Begin
   TrEN:='Quit NewsMaster? Changes will be lost.';Exit;End;
 If S='Quitter NewsMaster ?' Then Begin TrEN:='Quit NewsMaster?';Exit;End;
 If S=#133' la page' Then Begin TrEN:='Go to Page';Exit;End;
 If S='Num'#130'ro de page :' Then Begin TrEN:='Page number:';Exit;End;
 If S=#192' propos de NewsMaster' Then Begin TrEN:='About NewsMaster';Exit;End;
 If S='NewsMaster - Clone Pascal' Then Begin TrEN:='NewsMaster - Pascal clone';
   Exit;End;
 If S='Programme de publication de journaux' Then Begin
   TrEN:='Newsletter publishing program';Exit;End;
 If S='Inspir'#130' de News Master (Unison World, 1986)' Then Begin
   TrEN:='Inspired by News Master (Unison World, 1986)';Exit;End;
 If S='Pages : ' Then Begin TrEN:='Pages: ';Exit;End;
 If S='Texte principal : ' Then Begin TrEN:='Main text: ';Exit;End;
 If S=' caract'#138'res' Then Begin TrEN:=' characters';Exit;End;
 If S='Images et traits : ' Then Begin TrEN:='Artwork and lines: ';Exit;End;
 If S='Polices disponibles : ' Then Begin TrEN:='Available fonts: ';Exit;End;
 If S=' (int'#130'gr'#130'es)' Then Begin TrEN:=' (built-in)';Exit;End;
 If S='ATTENTION : du texte d'#130'passe la mise en page' Then Begin
   TrEN:='WARNING: text overflows the layout';Exit;End;
 If S='Statistiques' Then Begin TrEN:='Statistics';Exit;End;
 If S='M'#130'moire' Then Begin TrEN:='Memory';Exit;End;
 If S='M'#130'moire g'#130'r'#130'e par Free Pascal.' Then Begin
   TrEN:='Memory managed by Free Pascal.';Exit;End;
 If S='Plus grand bloc libre : ' Then Begin TrEN:='Largest free block: ';Exit;
   End;
 If S='M'#130'moire libre : ' Then Begin TrEN:='Free memory: ';Exit;End;
 If S='CRAZY JOE''S FISH SHACK' Then Begin TrEN:='CRAZY JOE''S FISH SHACK';Exit;
   End;
 If S='Attrapez nos portions de taille BALEINE '#133' prix de sardine !' Then
   Begin TrEN:='Catch our WHALE size portions at sardine prices!';Exit;End;
 If S='Sp'#130'cial du jour' Then Begin TrEN:='Today''s special';Exit;End;
 If S='Flet frit : 5,25 $. Notre cuisinier, un ancien marin au grand coeur, '
   Then Begin
   TrEN:='Fried flounder: $5.25. Our cook, a former sailor with a heart of '+
   'gold, ';Exit;End;
 If S='pr'#130'pare chaque matin le poisson le plus frais du port. ' Then Begin
   TrEN:='prepares the freshest fish from the harbor every morning. ';Exit;End;
 If S='Servi avec des frites maison, une salade croquante et la fameuse sauce '+
   'secr'#138'te de la maison.' Then Begin
   TrEN:='Served with homemade fries, a crisp salad and the famous secret '+
   'house sauce.';Exit;End;
 If S='Chaudr'#130'e de palourdes : 3,95 $. Une soupe onctueuse '#133' la '+
   'cr'#138'me, ' Then Begin
   TrEN:='Clam chowder: $3.95. A smooth, creamy soup, ';Exit;End;
 If S='garnie de palourdes, de pommes de terre et de lard fum'#130'. '+
   'Id'#130'ale ' Then Begin
   TrEN:='topped with clams, potatoes and smoked bacon. Perfect ';Exit;End;
 If S='pour r'#130'chauffer les journ'#130'es d''hiver sur le quai.' Then Begin
   TrEN:='for warming up winter days on the dock.';Exit;End;
 If S='Plateau de fruits de mer : 7,99 $. ' Then Begin
   TrEN:='Seafood platter: $7.99. ';Exit;End;
 If S='Crevettes, p'#130'tonles, calmars et moules, accompagn'#130's de '+
   'citron et de beurre fondu. ' Then Begin
   TrEN:='Shrimp, scallops, squid and mussels, served with lemon and melted '+
   'butter. ';Exit;End;
 If S='Le plateau est servi sur glace pour garder toute la fra'#139'cheur de '+
   'la mer. ' Then Begin
   TrEN:='The platter is served on ice to keep all the freshness of the sea. ';
   Exit;End;
 If S='Venez nombreux, la maison offre le caf'#130' !' Then Begin
   TrEN:='Come one, come all, coffee is on the house!';Exit;End;
End;

Function TrDE(Const S: String): String;
Begin
 TrDE:='';
 If S='NEWSMASTER - CLONE VERSION ' Then Begin
   TrDE:='NEWSMASTER - KLON VERSION ';Exit;End;
 If S='PROGRAMME DE PUBLICATION DE JOURNAUX' Then Begin
   TrDE:='PROGRAMM ZUR ZEITUNGSGESTALTUNG';Exit;End;
 If S='D''APRES NEWS MASTER (UNISON WORLD, 1986)' Then Begin
   TrDE:='NACH NEWS MASTER (UNISON WORLD, 1986)';Exit;End;
 If S='APPUYEZ SUR ESPACE POUR CONTINUER' Then Begin
   TrDE:='LEERTASTE ZUM FORTFAHREN DR'#154'CKEN';Exit;End;
 If S='NewsMaster : Menu principal' Then Begin TrDE:='NewsMaster: Hauptmen'#129;
   Exit;End;
 If S='Choisissez une activit'#130' :' Then Begin
   TrDE:='W'#132'hlen Sie eine Aktivit'#132't:';Exit;End;
 If S='Commencer un nouveau journal' Then Begin TrDE:='Neue Zeitung beginnen';
   Exit;End;
 If S='Continuer le journal courant' Then Begin
   TrDE:='Aktuelle Zeitung weiterbearbeiten';Exit;End;
 If S='Choisir un journal enregistr'#130 Then Begin
   TrDE:='Gespeicherte Zeitung ausw'#132'hlen';Exit;End;
 If S='Quitter NewsMaster' Then Begin TrDE:='NewsMaster beenden';Exit;End;
 If S='ENTR'#144'E : POINT FINAL' Then Begin TrDE:='EINGABE: ENDPUNKT';Exit;End;
 If S='OBJET AJOUT'#144 Then Begin TrDE:='OBJEKT HINZUGEF'#154'GT';Exit;End;
 If S='Clone graphique du programme de publication de journaux News Master.'
   Then Begin TrDE:='Grafischer Klon des Zeitungsprogramms News Master.';Exit;
   End;
 If S='Utilisation : NEWS [fichier.NWC] [/?]' Then Begin
   TrDE:='Aufruf: NEWS [datei.NWC] [/?]';Exit;End;
 If S='fichier.NWC  Journal '#133' ouvrir.' Then Begin
   TrDE:='datei.NWC    Zu '#148'ffnende Zeitung.';Exit;End;
 If S='/?           Affiche cette aide.' Then Begin
   TrDE:='/?           Diese Hilfe anzeigen.';Exit;End;
 If S='Langue : fran'#135'ais par d'#130'faut. LANGUAGE=EN : anglais, '+
   'LANGUAGE=GR : allemand.' Then Begin
   TrDE:='Sprache: Franz'#148'sisch als Standard. LANGUAGE=EN: Englisch, '+
   'LANGUAGE=GR: Deutsch.';Exit;End;
 If S='Place NEWS.FLB dans le r'#130'pertoire courant pour utiliser les '+
   'polices originales.' Then Begin
   TrDE:='NEWS.FLB ins aktuelle Verzeichnis legen, um die Originalschriften '+
   'zu nutzen.';Exit;End;
 If S='Couverts' Then Begin TrDE:='Besteck';Exit;End;
 If S='Poisson' Then Begin TrDE:='Fisch';Exit;End;
 If S='Etoile' Then Begin TrDE:='Stern';Exit;End;
 If S='Soleil' Then Begin TrDE:='Sonne';Exit;End;
 If S='Maison' Then Begin TrDE:='Haus';Exit;End;
 If S='Arbre' Then Begin TrDE:='Baum';Exit;End;
 If S='Ciseaux' Then Begin TrDE:='Schere';Exit;End;
 If S='Ballon' Then Begin TrDE:='Ballon';Exit;End;
 If S='Telephone' Then Begin TrDE:='Telefon';Exit;End;
 If S='Coeur' Then Begin TrDE:='Herz';Exit;End;
 If S='Fleche' Then Begin TrDE:='Pfeil';Exit;End;
 If S='Journal' Then Begin TrDE:='Zeitung';Exit;End;
 If S='Tasse' Then Begin TrDE:='Tasse';Exit;End;
 If S='Livre' Then Begin TrDE:='Buch';Exit;End;
 If S='Gauche' Then Begin TrDE:='Links';Exit;End;
 If S='Droite' Then Begin TrDE:='Rechts';Exit;End;
 If S='Centr'#130 Then Begin TrDE:='Zentriert';Exit;End;
 If S='Justifi'#130 Then Begin TrDE:='Blocksatz';Exit;End;
 If S='Texte par-dessus' Then Begin TrDE:='Text '#129'ber Bild';Exit;End;
 If S='Texte des deux c'#147't'#130's' Then Begin
   TrDE:='Text auf beiden Seiten';Exit;End;
 If S='Texte '#133' gauche seul' Then Begin TrDE:='Text nur links';Exit;End;
 If S='Texte '#133' droite seul' Then Begin TrDE:='Text nur rechts';Exit;End;
 If S='Zone d'#130'gag'#130'e' Then Begin TrDE:='Freihalten';Exit;End;
 If S='Grand pas (16)' Then Begin TrDE:='Gro'#225'er Schritt (16)';Exit;End;
 If S='Pas moyen (4)' Then Begin TrDE:='Mittlerer Schritt (4)';Exit;End;
 If S='Un point (1)' Then Begin TrDE:='Ein Punkt (1)';Exit;End;
 If S='Ligne' Then Begin TrDE:='Linie';Exit;End;
 If S='Bo'#140'te' Then Begin TrDE:='Rahmen';Exit;End;
 If S='Horizontalement' Then Begin TrDE:='Horizontal';Exit;End;
 If S='Verticalement' Then Begin TrDE:='Vertikal';Exit;End;
 If S='&Oui' Then Begin TrDE:='&Ja';Exit;End;
 If S='&Non' Then Begin TrDE:='&Nein';Exit;End;
 If S='&Annuler' Then Begin TrDE:='&Abbruch';Exit;End;
 If S='Fichier' Then Begin TrDE:='Datei';Exit;End;
 If S='Edition' Then Begin TrDE:='Bearbeiten';Exit;End;
 If S='Texte' Then Begin TrDE:='Text';Exit;End;
 If S='Image' Then Begin TrDE:='Bild';Exit;End;
 If S='Page' Then Begin TrDE:='Seite';Exit;End;
 If S='Vue' Then Begin TrDE:='Ansicht';Exit;End;
 If S='Options' Then Begin TrDE:='Optionen';Exit;End;
 If S=#192' propos de NewsMaster...' Then Begin TrDE:=#154'ber NewsMaster...';
   Exit;End;
 If S='Statistiques...' Then Begin TrDE:='Statistik...';Exit;End;
 If S='M'#130'moire libre' Then Begin TrDE:='Freier Speicher';Exit;End;
 If S='Menu principal...' Then Begin TrDE:='Hauptmen'#129'...';Exit;End;
 If S='Nouveau|^N' Then Begin TrDE:='Neu|^N';Exit;End;
 If S='Ouvrir...|^O' Then Begin TrDE:=#153'ffnen...|^O';Exit;End;
 If S='Enregistrer|^S' Then Begin TrDE:='Speichern|^S';Exit;End;
 If S='Enregistrer sous...' Then Begin TrDE:='Speichern unter...';Exit;End;
 If S='Importer texte ASCII...' Then Begin TrDE:='ASCII-Text importieren...';
   Exit;End;
 If S='Exporter texte ASCII...' Then Begin TrDE:='ASCII-Text exportieren...';
   Exit;End;
 If S='Imprimer la page (PBM)...' Then Begin TrDE:='Seite drucken (PBM)...';
   Exit;End;
 If S='Imprimer tout (PBM)...' Then Begin TrDE:='Alles drucken (PBM)...';Exit;
   End;
 If S='Quitter|^Q' Then Begin TrDE:='Beenden|^Q';Exit;End;
 If S='Annuler|^Z' Then Begin TrDE:='R'#129'ckg'#132'ngig|^Z';Exit;End;
 If S='Couper|^X' Then Begin TrDE:='Ausschneiden|^X';Exit;End;
 If S='Copier|^C' Then Begin TrDE:='Kopieren|^C';Exit;End;
 If S='Coller|^V' Then Begin TrDE:='Einf'#129'gen|^V';Exit;End;
 If S='Effacer|Suppr' Then Begin TrDE:='L'#148'schen|Entf';Exit;End;
 If S='Tout s'#130'lectionner|^A' Then Begin TrDE:='Alles markieren|^A';Exit;
   End;
 If S='Chercher...|^F' Then Begin TrDE:='Suchen...|^F';Exit;End;
 If S='Chercher suivant|^G' Then Begin TrDE:='Weitersuchen|^G';Exit;End;
 If S='Choisir la police...|^T' Then Begin TrDE:='Schrift w'#132'hlen...|^T';
   Exit;End;
 If S='Police pr'#130'c'#130'dente' Then Begin TrDE:='Vorherige Schrift';Exit;
   End;
 If S='Police suivante' Then Begin TrDE:='N'#132'chste Schrift';Exit;End;
 If S='Aligner '#133' gauche|^L' Then Begin TrDE:='Linksb'#129'ndig|^L';Exit;
   End;
 If S='Aligner '#133' droite|^R' Then Begin TrDE:='Rechtsb'#129'ndig|^R';Exit;
   End;
 If S='Centrer|^E' Then Begin TrDE:='Zentrieren|^E';Exit;End;
 If S='Justifier|^J' Then Begin TrDE:='Blocksatz|^J';Exit;End;
 If S='Marquer la s'#130'lection' Then Begin TrDE:='Auswahl markieren';Exit;End;
 If S='Mode '#130'dition du texte|F2' Then Begin TrDE:='Textmodus|F2';Exit;End;
 If S='Mode '#130'dition d''images|F3' Then Begin TrDE:='Bildmodus|F3';Exit;End;
 If S='Choisir une image...|F1' Then Begin TrDE:='Bild w'#132'hlen...|F1';Exit;
   End;
 If S='Prendre|F2' Then Begin TrDE:='Aufnehmen|F2';Exit;End;
 If S='Prendre une copie|F3' Then Begin TrDE:='Kopie aufnehmen|F3';Exit;End;
 If S='Poser|Entr'#130'e' Then Begin TrDE:='Ablegen|Eingabe';Exit;End;
 If S='Supprimer|Suppr' Then Begin TrDE:='L'#148'schen|Entf';Exit;End;
 If S='Agrandir|+' Then Begin TrDE:='Vergr'#148#225'ern|+';Exit;End;
 If S='R'#130'duire|-' Then Begin TrDE:='Verkleinern|-';Exit;End;
 If S='Taille d''origine' Then Begin TrDE:='Originalgr'#148#225'e';Exit;End;
 If S='Retourner horizontal.' Then Begin TrDE:='Horizontal spiegeln';Exit;End;
 If S='Retourner vertical.' Then Begin TrDE:='Vertikal spiegeln';Exit;End;
 If S='Tracer une ligne' Then Begin TrDE:='Linie zeichnen';Exit;End;
 If S='Tracer une bo'#140'te' Then Begin TrDE:='Rahmen zeichnen';Exit;End;
 If S='Motif de remplissage...' Then Begin TrDE:='F'#129'llmuster...';Exit;End;
 If S=#144'paisseur du trait...' Then Begin TrDE:='Linienst'#132'rke...';Exit;
   End;
 If S='Mode mise en page|F4' Then Begin TrDE:='Layoutmodus|F4';Exit;End;
 If S='Ajouter une colonne' Then Begin TrDE:='Spalte hinzuf'#129'gen';Exit;End;
 If S='Supprimer une colonne' Then Begin TrDE:='Spalte l'#148'schen';Exit;End;
 If S='Ajouter un titre' Then Begin TrDE:='Titel hinzuf'#129'gen';Exit;End;
 If S='Supprimer le titre' Then Begin TrDE:='Titel l'#148'schen';Exit;End;
 If S='Ajouter une page' Then Begin TrDE:='Seite hinzuf'#129'gen';Exit;End;
 If S='Supprimer la page' Then Begin TrDE:='Seite l'#148'schen';Exit;End;
 If S='Page pr'#130'c'#130'dente|PgHaut' Then Begin
   TrDE:='Vorherige Seite|BildAuf';Exit;End;
 If S='Page suivante|PgBas' Then Begin TrDE:='N'#132'chste Seite|BildAb';Exit;
   End;
 If S=#133' la page...' Then Begin TrDE:='Gehe zu Seite...';Exit;End;
 If S='Zoom avant (x2)' Then Begin TrDE:='Vergr'#148#225'ern (x2)';Exit;End;
 If S='Vue normale' Then Begin TrDE:='Normalansicht';Exit;End;
 If S='Largeur de la page' Then Begin TrDE:='Seitenbreite';Exit;End;
 If S='Page enti'#138're' Then Begin TrDE:='Ganze Seite';Exit;End;
 If S='Pas du curseur : grand' Then Begin TrDE:='Cursorschritt: gro'#225;Exit;
   End;
 If S='Pas du curseur : moyen' Then Begin TrDE:='Cursorschritt: mittel';Exit;
   End;
 If S='Pas du curseur : point' Then Begin TrDE:='Cursorschritt: Punkt';Exit;End;
 If S='Polices de NEWS.FLB' Then Begin TrDE:='Schriften aus NEWS.FLB';Exit;End;
 If S='Guides de colonnes' Then Begin TrDE:='Spaltenf'#129'hrung';Exit;End;
 If S='Afficher les infos...' Then Begin TrDE:='Info...';Exit;End;
 If S='MENU D'''#144'DITION PRINCIPAL' Then Begin
   TrDE:='HAUPTMEN'#154' BEARBEITEN';Exit;End;
 If S='VUE' Then Begin TrDE:='ANSICHT';Exit;End;
 If S='TEXTE' Then Begin TrDE:='TEXT';Exit;End;
 If S='IMAGES' Then Begin TrDE:='BILDER';Exit;End;
 If S='PAGE' Then Begin TrDE:='SEITE';Exit;End;
 If S='FICHIER' Then Begin TrDE:='DATEI';Exit;End;
 If S='IMPRIM.' Then Begin TrDE:='DRUCK';Exit;End;
 If S='CHANGER LA VUE DU JOURNAL' Then Begin TrDE:='SEITENANSICHT '#142'NDERN';
   Exit;End;
 If S='ZOOM|AVANT' Then Begin TrDE:='ZOOM|GROSS';Exit;End;
 If S='VUE|NORMALE' Then Begin TrDE:='NORMAL|ANSICHT';Exit;End;
 If S='LARGEUR|DE PAGE' Then Begin TrDE:='SEITEN-|BREITE';Exit;End;
 If S='PAGE|ENTI'#138'RE' Then Begin TrDE:='GANZE|SEITE';Exit;End;
 If S='PAGE|PR'#144'C.' Then Begin TrDE:='SEITE|ZUR'#154'CK';Exit;End;
 If S='PAGE|SUIV.' Then Begin TrDE:='N'#142'CHSTE|SEITE';Exit;End;
 If S='MODIFIER LE TEXTE' Then Begin TrDE:='TEXT BEARBEITEN';Exit;End;
 If S='CHOISIR|POLICE' Then Begin TrDE:='SCHRIFT|W'#142'HLEN';Exit;End;
 If S='ALIGNE-|MENT' Then Begin TrDE:='AUS-|RICHTEN';Exit;End;
 If S='S'#144'LEC-|TION' Then Begin TrDE:='MARKIE-|REN';Exit;End;
 If S='COUPER' Then Begin TrDE:='AUSSCH.';Exit;End;
 If S='COPIER' Then Begin TrDE:='KOPIE';Exit;End;
 If S='COLLER' Then Begin TrDE:='EINF'#154'G.';Exit;End;
 If S='IMPORT|ASCII' Then Begin TrDE:='ASCII|IMPORT';Exit;End;
 If S='ANNULER' Then Begin TrDE:='R'#154'CKG.';Exit;End;
 If S='MODIFIER LES IMAGES' Then Begin TrDE:='BILDER BEARBEITEN';Exit;End;
 If S='CHOISIR|IMAGE' Then Begin TrDE:='BILD|W'#142'HLEN';Exit;End;
 If S='PRENDRE' Then Begin TrDE:='NEHMEN';Exit;End;
 If S='PRENDRE|COPIE' Then Begin TrDE:='KOPIE|NEHMEN';Exit;End;
 If S='POSER' Then Begin TrDE:='ABLEGEN';Exit;End;
 If S='TAILLE' Then Begin TrDE:='GR'#153'SSE';Exit;End;
 If S='ROGNER' Then Begin TrDE:='BESCHN.';Exit;End;
 If S='HABIL-|LAGE' Then Begin TrDE:='TEXT-|FLUSS';Exit;End;
 If S='RETOUR-|NER' Then Begin TrDE:='SPIEGEL';Exit;End;
 If S='LIGNE|BO'#139'TE' Then Begin TrDE:='LINIE|RAHMEN';Exit;End;
 If S='SUPPR.' Then Begin TrDE:='L'#153'SCHEN';Exit;End;
 If S='MODIFIER LA MISE EN PAGE' Then Begin TrDE:='SEITENLAYOUT '#142'NDERN';
   Exit;End;
 If S='AJOUT|COLONNE' Then Begin TrDE:='SPALTE|NEU';Exit;End;
 If S='SUPPR.|COLONNE' Then Begin TrDE:='SPALTE|L'#153'SCHEN';Exit;End;
 If S='AJOUT|TITRE' Then Begin TrDE:='TITEL|NEU';Exit;End;
 If S='SUPPR.|TITRE' Then Begin TrDE:='TITEL|L'#153'SCHEN';Exit;End;
 If S='AJOUT|PAGE' Then Begin TrDE:='SEITE|NEU';Exit;End;
 If S='SUPPR.|PAGE' Then Begin TrDE:='SEITE|L'#153'SCHEN';Exit;End;
 If S='CHARGER ET ENREGISTRER' Then Begin TrDE:='LADEN UND SPEICHERN';Exit;End;
 If S='NOUVEAU' Then Begin TrDE:='NEU';Exit;End;
 If S='OUVRIR' Then Begin TrDE:='LADEN';Exit;End;
 If S='ENREG.' Then Begin TrDE:='SPEICH.';Exit;End;
 If S='ENREG.|SOUS' Then Begin TrDE:='SPEICH.|UNTER';Exit;End;
 If S='MENU|PRINC.' Then Begin TrDE:='HAUPT-|MEN'#154;Exit;End;
 If S='QUITTER' Then Begin TrDE:='ENDE';Exit;End;
 If S='IMPRIMER LE JOURNAL' Then Begin TrDE:='ZEITUNG DRUCKEN';Exit;End;
 If S='CETTE|PAGE' Then Begin TrDE:='DIESE|SEITE';Exit;End;
 If S='TOUTES|PAGES' Then Begin TrDE:='ALLE|SEITEN';Exit;End;
 If S='EXPORT|TEXTE' Then Begin TrDE:='TEXT-|EXPORT';Exit;End;
 If S='ZOOM X2' Then Begin TrDE:='ZOOM X2';Exit;End;
 If S='NORMALE' Then Begin TrDE:='NORMAL';Exit;End;
 If S='LARGEUR' Then Begin TrDE:='BREITE';Exit;End;
 If S='PAGE ENTI'#138'RE' Then Begin TrDE:='GANZE SEITE';Exit;End;
 If S='PAS ' Then Begin TrDE:='SCHRITT ';Exit;End;
 If S='ROGNAGE' Then Begin TrDE:='BESCHNITT';Exit;End;
 If S='TRAC'#144 Then Begin TrDE:='ZEICHNEN';Exit;End;
 If S='SANS NOM' Then Begin TrDE:='OHNE NAME';Exit;End;
 If S='PAGE ' Then Begin TrDE:='SEITE ';Exit;End;
 If S='TEXTE EN TROP' Then Begin TrDE:='TEXT ZU LANG';Exit;End;
 If S='MISE EN PAGE - PAGE ' Then Begin TrDE:='SEITENLAYOUT - SEITE ';Exit;End;
 If S=' COLONNES' Then Begin TrDE:=' SPALTEN';Exit;End;
 If S=' COLONNE' Then Begin TrDE:=' SPALTE';Exit;End;
 If S=' + TITRE' Then Begin TrDE:=' + TITEL';Exit;End;
 If S='TEXTE TROP LONG' Then Begin TrDE:='TEXT ZU LANG';Exit;End;
 If S=' CARACT'#138'RES COPI'#144'S' Then Begin TrDE:=' ZEICHEN KOPIERT';Exit;
   End;
 If S='MARQUEZ AVEC LES FL'#138'CHES' Then Begin
   TrDE:='MIT PFEILTASTEN MARKIEREN';Exit;End;
 If S='S'#144'LECTION FIX'#144'E' Then Begin TrDE:='AUSWAHL FIXIERT';Exit;End;
 If S='Choisir une police' Then Begin TrDE:='Schrift w'#132'hlen';Exit;End;
 If S=' polices' Then Begin TrDE:=' Schriften';Exit;End;
 If S='int'#130'gr'#130'es' Then Begin TrDE:='eingebaut';Exit;End;
 If S='INTROUVABLE' Then Begin TrDE:='NICHT GEFUNDEN';Exit;End;
 If S='Chercher' Then Begin TrDE:='Suchen';Exit;End;
 If S='Texte '#133' chercher :' Then Begin TrDE:='Suchtext:';Exit;End;
 If S='TROP D''OBJETS' Then Begin TrDE:='ZU VIELE OBJEKTE';Exit;End;
 If S='RIEN A POSER' Then Begin TrDE:='NICHTS ZUM ABLEGEN';Exit;End;
 If S='AUCUNE IMAGE ICI' Then Begin TrDE:='KEIN BILD HIER';Exit;End;
 If S='Choisir une image' Then Begin TrDE:='Bild w'#132'hlen';Exit;End;
 If S='Fl'#138'ches : choisir  Entr'#130'e : valider' Then Begin
   TrDE:='Pfeile: w'#132'hlen  Eingabe: OK';Exit;End;
 If S='M'#138'ME PAGE SVP' Then Begin TrDE:='BITTE GLEICHE SEITE';Exit;End;
 If S='ENTR'#144'E : POINT DE D'#144'PART' Then Begin
   TrDE:='EINGABE: STARTPUNKT';Exit;End;
 If S='Motif de remplissage' Then Begin TrDE:='F'#129'llmuster';Exit;End;
 If S=#144'paisseur' Then Begin TrDE:='St'#132'rke';Exit;End;
 If S='Epaisseur du trait (1-12) :' Then Begin
   TrDE:='Linienst'#132'rke (1-12):';Exit;End;
 If S='MAXIMUM : ' Then Begin TrDE:='MAXIMAL: ';Exit;End;
 If S='UNE COLONNE MINIMUM' Then Begin TrDE:='MINDESTENS EINE SPALTE';Exit;End;
 If S='TITRE D'#144'J'#133' PR'#144'SENT' Then Begin
   TrDE:='TITEL SCHON VORHANDEN';Exit;End;
 If S='Titre' Then Begin TrDE:='Titel';Exit;End;
 If S=' PAGES' Then Begin TrDE:=' SEITEN';Exit;End;
 If S='IMPOSSIBLE : UNE PAGE' Then Begin TrDE:='UNM'#153'GLICH: NUR EINE SEITE';
   Exit;End;
 If S='TEXTE TRONQU'#144 Then Begin TrDE:='TEXT GEK'#154'RZT';Exit;End;
 If S='Fichier :' Then Begin TrDE:='Datei:';Exit;End;
 If S='(aucun fichier ' Then Begin TrDE:='(keine Datei ';Exit;End;
 If S='Impression de la page ' Then Begin TrDE:='Drucke Seite ';Exit;End;
 If S='Impression' Then Begin TrDE:='Drucken';Exit;End;
 If S='Page ' Then Begin TrDE:='Seite ';Exit;End;
 If S=' enregistr'#130'e dans ' Then Begin TrDE:=' gespeichert in ';Exit;End;
 If S='Pages enregistr'#130'es : ' Then Begin TrDE:='Gespeicherte Seiten: ';
   Exit;End;
 If S='Format : bitmap PBM ' Then Begin TrDE:='Format: PBM-Bitmap ';Exit;End;
 If S='Erreur d'''#130'criture du fichier.' Then Begin
   TrDE:='Fehler beim Schreiben der Datei.';Exit;End;
 If S='Titre du journal' Then Begin TrDE:='Titel der Zeitung';Exit;End;
 If S='Les changements non enregistr'#130's seront perdus. Continuer ?' Then
   Begin TrDE:='Nicht gespeicherte '#142'nderungen gehen verloren. Fortfahren?';
   Exit;End;
 If S='Ouvrir un journal' Then Begin TrDE:='Zeitung '#148'ffnen';Exit;End;
 If S='Ouvrir' Then Begin TrDE:=#153'ffnen';Exit;End;
 If S='Fichier introuvable : ' Then Begin TrDE:='Datei nicht gefunden: ';Exit;
   End;
 If S='JOURNAL CHARG'#144 Then Begin TrDE:='ZEITUNG GELADEN';Exit;End;
 If S='Ce fichier n''est pas un journal NewsMaster valide.' Then Begin
   TrDE:='Diese Datei ist keine g'#129'ltige NewsMaster-Zeitung.';Exit;End;
 If S='Enregistrer le journal' Then Begin TrDE:='Zeitung speichern';Exit;End;
 If S='Enregistrer' Then Begin TrDE:='Speichern';Exit;End;
 If S='Le fichier ' Then Begin TrDE:='Die Datei ';Exit;End;
 If S=' existe. Le remplacer ?' Then Begin TrDE:=' existiert. Ersetzen?';Exit;
   End;
 If S='JOURNAL ENREGISTR'#144 Then Begin TrDE:='ZEITUNG GESPEICHERT';Exit;End;
 If S='Importer du texte ASCII' Then Begin TrDE:='ASCII-Text importieren';Exit;
   End;
 If S='Importer' Then Begin TrDE:='Importieren';Exit;End;
 If S='Impossible de lire ' Then Begin TrDE:='Kann nicht lesen: ';Exit;End;
 If S='Exporter le texte ASCII' Then Begin TrDE:='ASCII-Text exportieren';Exit;
   End;
 If S='TEXTE EXPORT'#144 Then Begin TrDE:='TEXT EXPORTIERT';Exit;End;
 If S='Exporter' Then Begin TrDE:='Exportieren';Exit;End;
 If S='Quitter NewsMaster ? Les changements seront perdus.' Then Begin
   TrDE:='NewsMaster beenden? '#142'nderungen gehen verloren.';Exit;End;
 If S='Quitter NewsMaster ?' Then Begin TrDE:='NewsMaster beenden?';Exit;End;
 If S=#133' la page' Then Begin TrDE:='Gehe zu Seite';Exit;End;
 If S='Num'#130'ro de page :' Then Begin TrDE:='Seitennummer:';Exit;End;
 If S=#192' propos de NewsMaster' Then Begin TrDE:=#154'ber NewsMaster';Exit;
   End;
 If S='NewsMaster - Clone Pascal' Then Begin TrDE:='NewsMaster - Pascal-Klon';
   Exit;End;
 If S='Programme de publication de journaux' Then Begin
   TrDE:='Programm zur Zeitungsgestaltung';Exit;End;
 If S='Inspir'#130' de News Master (Unison World, 1986)' Then Begin
   TrDE:='Inspiriert von News Master (Unison World, 1986)';Exit;End;
 If S='Pages : ' Then Begin TrDE:='Seiten: ';Exit;End;
 If S='Texte principal : ' Then Begin TrDE:='Haupttext: ';Exit;End;
 If S=' caract'#138'res' Then Begin TrDE:=' Zeichen';Exit;End;
 If S='Images et traits : ' Then Begin TrDE:='Bilder und Linien: ';Exit;End;
 If S='Polices disponibles : ' Then Begin TrDE:='Verf'#129'gbare Schriften: ';
   Exit;End;
 If S=' (int'#130'gr'#130'es)' Then Begin TrDE:=' (eingebaut)';Exit;End;
 If S='ATTENTION : du texte d'#130'passe la mise en page' Then Begin
   TrDE:='ACHTUNG: Text passt nicht ins Layout';Exit;End;
 If S='Statistiques' Then Begin TrDE:='Statistik';Exit;End;
 If S='M'#130'moire' Then Begin TrDE:='Speicher';Exit;End;
 If S='M'#130'moire g'#130'r'#130'e par Free Pascal.' Then Begin
   TrDE:='Speicher wird von Free Pascal verwaltet.';Exit;End;
 If S='Plus grand bloc libre : ' Then Begin
   TrDE:='Gr'#148#225'ter freier Block: ';Exit;End;
 If S='M'#130'moire libre : ' Then Begin TrDE:='Freier Speicher: ';Exit;End;
 If S='CRAZY JOE''S FISH SHACK' Then Begin TrDE:='CRAZY JOE''S FISCHBUDE';Exit;
   End;
 If S='Attrapez nos portions de taille BALEINE '#133' prix de sardine !' Then
   Begin TrDE:='Schnappen Sie sich unsere WAL-Portionen zum Sardinenpreis!';
   Exit;End;
 If S='Sp'#130'cial du jour' Then Begin TrDE:='Tagesangebot';Exit;End;
 If S='Flet frit : 5,25 $. Notre cuisinier, un ancien marin au grand coeur, '
   Then Begin
   TrDE:='Gebratene Flunder: 5,25 $. Unser Koch, ein ehemaliger Seemann mit '+
   'gro'#225'em Herz, ';Exit;End;
 If S='pr'#130'pare chaque matin le poisson le plus frais du port. ' Then Begin
   TrDE:='bereitet jeden Morgen den frischesten Fisch des Hafens zu. ';Exit;End;
 If S='Servi avec des frites maison, une salade croquante et la fameuse sauce '+
   'secr'#138'te de la maison.' Then Begin
   TrDE:='Serviert mit hausgemachten Pommes, knackigem Salat und der '+
   'ber'#129'hmten geheimen Hausso'#225'e.';Exit;End;
 If S='Chaudr'#130'e de palourdes : 3,95 $. Une soupe onctueuse '#133' la '+
   'cr'#138'me, ' Then Begin
   TrDE:='Muschelsuppe: 3,95 $. Eine s'#132'mige Suppe mit Sahne, ';Exit;End;
 If S='garnie de palourdes, de pommes de terre et de lard fum'#130'. '+
   'Id'#130'ale ' Then Begin
   TrDE:='mit Muscheln, Kartoffeln und R'#132'ucherspeck. Ideal ';Exit;End;
 If S='pour r'#130'chauffer les journ'#130'es d''hiver sur le quai.' Then Begin
   TrDE:='um kalte Wintertage am Kai zu erw'#132'rmen.';Exit;End;
 If S='Plateau de fruits de mer : 7,99 $. ' Then Begin
   TrDE:='Meeresfr'#129'chteplatte: 7,99 $. ';Exit;End;
 If S='Crevettes, p'#130'tonles, calmars et moules, accompagn'#130's de '+
   'citron et de beurre fondu. ' Then Begin
   TrDE:='Garnelen, Jakobsmuscheln, Tintenfisch und Miesmuscheln mit Zitrone '+
   'und zerlassener Butter. ';Exit;End;
 If S='Le plateau est servi sur glace pour garder toute la fra'#139'cheur de '+
   'la mer. ' Then Begin
   TrDE:='Die Platte wird auf Eis serviert, damit die Frische des Meeres '+
   'erhalten bleibt. ';Exit;End;
 If S='Venez nombreux, la maison offre le caf'#130' !' Then Begin
   TrDE:='Kommen Sie zahlreich, der Kaffee geht aufs Haus!';Exit;End;
End;

Function Tr(Const S: String): String;
Var R: String; P: Integer;
Begin
 Tr:=S;
 If Lang=0 Then Exit;
 If Lang=1 Then R:=TrEN(S) Else R:=TrDE(S);
 If R<>'' Then Begin Tr:=R;Exit;End;
 P:=Pos('|',S);
 If P>0 Then Tr:=Tr(Copy(S,1,P-1))+'|'+Tr(Copy(S,P+1,255));
End;

{ ====================================================================== }
{                              POLICES                                   }
{ ====================================================================== }
{ Deux sources de polices :                                              }
{  - NEWS.FLB (bibliotheque de polices originale de News Master), lue    }
{    directement si le fichier est present dans le repertoire courant ;  }
{  - polices integrees, produites a partir de la police 8x8 du BGI.      }

Function GBit(C,X,Y: Integer): Integer;
Begin
 If (X<0) Or (X>7) Or (Y<0) Or (Y>7) Then GBit:=0
 Else If (G8[C,Y] And ($80 Shr X))<>0 Then GBit:=1 Else GBit:=0;
End;

{ Lit la police 8x8 du BGI }
Procedure ReadBios8;
Var C,X,Y: Integer;
Begin
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
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
 LastFill:=-1;
End;

{ Lissage EPX d'une police doublee (X,Y dans 0..15) }
Function EpxBit(C,X,Y: Integer): Integer;
Var SX,SY,P,A,B,Cc,D,Q: Integer;
Begin
 SX:=X Shr 1;SY:=Y Shr 1;
 P:=GBit(C,SX,SY);A:=GBit(C,SX,SY-1);B:=GBit(C,SX+1,SY);
 Cc:=GBit(C,SX-1,SY);D:=GBit(C,SX,SY+1);
 Q:=P;
 Case (X And 1)+2*(Y And 1) Of
  0: If (Cc=A) And (Cc<>D) And (A<>B) Then Q:=A;
  1: If (A=B) And (A<>Cc) And (B<>D) Then Q:=B;
  2: If (D=Cc) And (D<>B) And (Cc<>A) Then Q:=Cc;
  3: If (B=D) And (B<>A) And (D<>Cc) Then Q:=D;
 End;
 EpxBit:=Q;
End;

{ Bit de la police integree a l'echelle K }
Function SysBit(C,K,X,Y: Integer): Integer;
Begin
 If (X<0) Or (Y<0) Or (X>=8*K) Or (Y>=8*K) Then SysBit:=0
 Else If K=1 Then SysBit:=GBit(C,X,Y)
 Else If (K And 1)=0 Then SysBit:=EpxBit(C,X Div (K Div 2),Y Div (K Div 2))
 Else SysBit:=GBit(C,X Div K,Y Div K);
End;

{ Caractere de remplacement pour les polices ne contenant que l'ASCII }
Function FoldCh(C: Byte): Byte;
Begin
 Case C Of
  128: FoldCh:=67;
  129,150,151,163: FoldCh:=117;
  130,136,137,138: FoldCh:=101;
  131,132,133,134,160: FoldCh:=97;
  135: FoldCh:=99;
  139,140,141,161: FoldCh:=105;
  142,143: FoldCh:=65;
  144: FoldCh:=69;
  147,148,149,162: FoldCh:=111;
  152: FoldCh:=121;
  153: FoldCh:=79;
  154: FoldCh:=85;
  164: FoldCh:=110;
  165: FoldCh:=78;
  225: FoldCh:=115;
 Else
  If C<128 Then FoldCh:=C Else FoldCh:=63;
 End;
End;

Procedure SysMetrics(C,K: Integer; Var L,R: Integer);
Var X,Y: Integer;
Begin
 L:=99;R:=-1;
 For Y:=0 To 7 Do
  For X:=0 To 7 Do
   If GBit(C,X,Y)=1 Then Begin
    If X<L Then L:=X;
    If X>R Then R:=X;
   End;
End;

{ Construit une police integree : echelle K, style 0 normal 1 gras 2 italique }
Procedure BuildSysFont(F: Integer);
Var K,Sty,C,X,Y,L,R,W,H,Bpr,T,Sh,ShRow,Pass,J,SX,Lo,Hi: Integer;
    Sz,O: LongInt; Buf: PBytes; Bit: Boolean;
Begin
 K:=FSys[F] Shr 2;Sty:=FSys[F] And 3;
 H:=8*K;
 T:=1;Sh:=0;
 If Sty=1 Then T:=1+(K+2) Div 3;
 If Sty=2 Then Sh:=(H-1) Div 4;
 If K>=4 Then Begin Lo:=32;Hi:=127;End Else Begin Lo:=32;Hi:=255;End;
 GetMem(FOff[F],SizeOf(TWords));
 GetMem(FAdv[F],256);
 For C:=0 To 255 Do Begin FOff[F]^[C]:=$FFFF;FAdv[F]^[C]:=0;End;
 Buf:=Nil;
 For Pass:=1 To 2 Do Begin
  Sz:=0;
  For C:=Lo To Hi Do Begin
   SysMetrics(C,K,L,R);
   If R<0 Then Begin
    If C=32 Then FAdv[F]^[C]:=3*K+FGap[F];
    Continue;
   End;
   W:=(R-L+1)*K+(T-1)+Sh;
   Bpr:=(W+7) Shr 3;
   If Pass=2 Then Begin
    O:=Sz;
    FOff[F]^[C]:=Word(O);
    FAdv[F]^[C]:=Byte(W+FGap[F]);
    Buf^[O]:=0;Buf^[O+1]:=W;Buf^[O+2]:=7*K;Buf^[O+3]:=H;
    FillChar(Buf^[O+4],H*Bpr,0);
    For Y:=0 To H-1 Do Begin
     If Sty=2 Then ShRow:=(H-1-Y) Div 4 Else ShRow:=0;
     For X:=0 To W-1 Do Begin
      Bit:=False;
      For J:=0 To T-1 Do Begin
       SX:=L*K+X-ShRow-J;
       If SysBit(C,K,SX,Y)=1 Then Bit:=True;
      End;
      If Bit Then Buf^[O+4+Y*Bpr+(X Shr 3)]:=Buf^[O+4+Y*Bpr+(X Shr 3)] Or ($80
        Shr (X And 7));
     End;
    End;
   End;
   Sz:=Sz+4+H*Bpr;
  End;
  If Pass=1 Then Begin
   GetMem(Buf,Sz);
   FLen[F]:=Sz;
  End;
 End;
 FBuf[F]:=Buf;
 { caracteres absents : repli sur le caractere ASCII de base }
 For C:=0 To 255 Do
  If FOff[F]^[C]=$FFFF Then
   If (C<>32) And (FoldCh(C)<>C) And (FOff[F]^[FoldCh(C)]<>$FFFF) Then Begin
    FOff[F]^[C]:=FOff[F]^[FoldCh(C)];
    FAdv[F]^[C]:=FAdv[F]^[FoldCh(C)];
   End;
 FAdv[F]^[13]:=0;
End;

Procedure AddSys(Const Nm: String; K,Sty: Integer);
Begin
 If NFont>=MAXFONT Then Exit;
 FName[NFont]:=Nm;FKind[NFont]:=1;FSys[NFont]:=K*4+Sty;
 FAsc[NFont]:=7*K;FDsc[NFont]:=K;FSpc[NFont]:=3*K+K;FGap[NFont]:=K;
 FBuf[NFont]:=Nil;FOff[NFont]:=Nil;FAdv[NFont]:=Nil;
 Inc(NFont);
End;

Procedure FreeFonts;
Var I: Integer;
Begin
 For I:=0 To MAXFONT-1 Do Begin
  If FBuf[I]<>Nil Then Begin FreeMem(FBuf[I],FLen[I]);FBuf[I]:=Nil;End;
  If FOff[I]<>Nil Then Begin FreeMem(FOff[I],SizeOf(TWords));FOff[I]:=Nil;End;
  If FAdv[I]<>Nil Then Begin FreeMem(FAdv[I],256);FAdv[I]:=Nil;End;
 End;
End;

Function Rd16(Var B; O: Integer): Integer;
Var P: PBytes;
Begin
 P:=@B;
 Rd16:=P^[O]+P^[O+1]*256;
End;

{ Cherche NEWS.FLB dans le repertoire courant, puis dans celui du programme }
Function FindFLB: Boolean;
Var D: String;
Begin
 FindFLB:=True;
 FLBFile:='NEWS.FLB';
 If FileExists(FLBFile) Then Exit;
 FLBFile:='news.flb';
 If FileExists(FLBFile) Then Exit;
 D:=ParamStr(0);
 While (Length(D)>0) And (D[Length(D)]<>'\') And (D[Length(D)]<>'/') Do
   Dec(D[0]);
 FLBFile:=D+'NEWS.FLB';
 If FileExists(FLBFile) Then Exit;
 FLBFile:=D+'news.flb';
 If FileExists(FLBFile) Then Exit;
 FindFLB:=False;
End;

{ Index des polices du fichier FLB (80 octets par police) }
Function LoadFLBIndex: Boolean;
Var Fh: File; Rec: Array[0..79] Of Byte; N,I,J: Integer; P0,Fs: LongInt;
    Pos: Array[0..MAXFONT] Of LongInt; Nm: String;
Begin
 LoadFLBIndex:=False;
 {$I-}
 Assign(Fh,FLBFile);Reset(Fh,1);
 {$I+}
 If IOResult<>0 Then Exit;
 Fs:=FileSize(Fh);
 BlockRead(Fh,Rec,80);
 P0:=LongInt(Rec[6])+LongInt(Rec[7])*256+LongInt(Rec[8])*65536;
 N:=P0 Div 80;
 If (N<1) Or (N>MAXFONT) Or (P0>Fs) Then Begin Close(Fh);Exit;End;
 Seek(Fh,0);
 NFont:=0;
 For I:=0 To N-1 Do Begin
  BlockRead(Fh,Rec,80);
  Nm:='';J:=10;
  While (J<60) And (Rec[J]<>0) Do Begin Nm:=Nm+Chr(Rec[J]);Inc(J);End;
  FName[I]:=Nm;
  Pos[I]:=LongInt(Rec[6])+LongInt(Rec[7])*256+LongInt(Rec[8])*65536;
  FPos[I]:=Pos[I]+Rd16(Rec,60);
  FAsc[I]:=Rd16(Rec,70);FDsc[I]:=Rd16(Rec,72);
  FSpc[I]:=Rd16(Rec,74)+Rd16(Rec,78);FGap[I]:=Rd16(Rec,78);
  FKind[I]:=0;FBuf[I]:=Nil;FOff[I]:=Nil;FAdv[I]:=Nil;
  Inc(NFont);
 End;
 Pos[N]:=Fs;
 For I:=0 To N-1 Do Begin
  FLen[I]:=Pos[I+1]-FPos[I];
  If FLen[I]>64000 Then FLen[I]:=64000;
  If FLen[I]<512 Then FLen[I]:=512;
 End;
 Close(Fh);
 LoadFLBIndex:=True;
End;

Procedure LoadFLBFont(F: Integer);
Var Fh: File; C,J: Integer; Tb: Array[0..255] Of Byte; W: Word; Got: LongInt;
Begin
 GetMem(FOff[F],SizeOf(TWords));
 GetMem(FAdv[F],256);
 GetMem(FBuf[F],FLen[F]);
 FillChar(FBuf[F]^,FLen[F],0);
 For C:=0 To 255 Do Begin FOff[F]^[C]:=$FFFF;FAdv[F]^[C]:=0;End;
 {$I-}
 Assign(Fh,FLBFile);Reset(Fh,1);
 Seek(Fh,FPos[F]);
 BlockRead(Fh,FBuf[F]^,FLen[F],Got);
 Close(Fh);
 {$I+}
 If IOResult<>0 Then Exit;
 For C:=0 To 127 Do Begin
  W:=FBuf[F]^[C*2]+FBuf[F]^[C*2+1]*256;
  If (W<>$FFFF) And (LongInt(W)+260<FLen[F]) Then Begin
   FOff[F]^[C]:=W+256;
   FAdv[F]^[C]:=FBuf[F]^[W+256+1]+FGap[F];
  End;
 End;
 If FOff[F]^[32]=$FFFF Then FAdv[F]^[32]:=FSpc[F];
 For C:=128 To 255 Do Begin
  J:=FoldCh(C);
  FOff[F]^[C]:=FOff[F]^[J];
  FAdv[F]^[C]:=FAdv[F]^[J];
 End;
 FAdv[F]^[225]:=FAdv[F]^[115]*2;
 FAdv[F]^[13]:=0;
End;

Procedure EnsureFont(F: Integer);
Begin
 If F>=NFont Then F:=0;
 If FOff[F]<>Nil Then Exit;
 If FKind[F]=0 Then LoadFLBFont(F) Else BuildSysFont(F);
End;

Function FontByName(Const Nm: String): Integer;
Var I: Integer;
Begin
 FontByName:=-1;
 For I:=0 To NFont-1 Do
  If FName[I]=Nm Then Begin FontByName:=I;Exit;End;
End;

{ Police la plus proche (hauteur) pour remplacer une police absente }
Function NearestFont(Const Nm: String; Ht: Integer): Integer;
Var I,B,D,BD: Integer;
Begin
 B:=FontByName(Nm);
 If B>=0 Then Begin NearestFont:=B;Exit;End;
 B:=0;BD:=9999;
 For I:=0 To NFont-1 Do Begin
  D:=Abs(FAsc[I]+FDsc[I]-Ht);
  If Copy(FName[I],1,6)='glyphs' Then D:=D+500;
  If D<BD Then Begin BD:=D;B:=I;End;
 End;
 NearestFont:=B;
End;

Function FontHt(F: Integer): Integer;
Begin
 FontHt:=FAsc[F]+FDsc[F];
End;

Procedure PickDefaults;
Begin
 If UseFLB Then Begin
  DefBody:=FontByName('Park 10');
  DefHead:=FontByName('News 24 bold');
 End Else Begin
  DefBody:=FontByName('Systeme 8');
  DefHead:=FontByName('Titre 32');
 End;
 If DefBody<0 Then DefBody:=0;
 If DefHead<0 Then DefHead:=0;
End;

{ Construit la table des polices (UseFLB : polices de NEWS.FLB) }
Procedure BuildFontTable;
Var Ok: Boolean;
Begin
 FreeFonts;
 NFont:=0;
 Ok:=False;
 If UseFLB And FLBFound Then Ok:=LoadFLBIndex;
 If Not Ok Then Begin
  UseFLB:=False;
  NFont:=0;
  AddSys('Systeme 8',1,0);
  AddSys('Systeme 8 gras',1,1);
  AddSys('Systeme 8 italique',1,2);
  AddSys('Systeme 16',2,0);
  AddSys('Systeme 16 gras',2,1);
  AddSys('Systeme 16 italique',2,2);
  AddSys('Systeme 24',3,0);
  AddSys('Systeme 24 gras',3,1);
  AddSys('Titre 32',4,1);
  AddSys('Titre 48',6,1);
 End;
 PickDefaults;
End;

{ Largeur d'un caractere (points a l'echelle 1:1) }
Function CharAdv(F,C: Byte): Integer;
Begin
 If C=13 Then Begin CharAdv:=0;Exit;End;
 If F>=NFont Then F:=0;
 EnsureFont(F);
 CharAdv:=FAdv[F]^[C];
End;

{ Trace un morceau horizontal (echelle K) }
Procedure PlotRun(X1,X2,Y,K: Integer);
Begin
 If K=1 Then Line(X1,Y,X2,Y) Else Bar(X1,Y,X2,Y+K-1);
End;

{ Type d'accent d'un caractere CP437 (les polices NEWS.FLB sont ASCII) }
Function AccentOf(C: Byte): Integer;
Begin
 Case C Of
  130,144,160,161,162,163: AccentOf:=1;
  133,138,141,149,151: AccentOf:=2;
  131,136,140,147,150,143: AccentOf:=3;
  132,137,139,148,129,142,153,154,152: AccentOf:=4;
  135,128: AccentOf:=5;
  164,165: AccentOf:=6;
 Else AccentOf:=0;
 End;
End;

Procedure DrawAccent(F,C,X,YB,K,W,YO: Integer);
Var U,CX,MY,S,A: Integer;
Begin
 A:=AccentOf(C);
 If A=0 Then Exit;
 U:=(FAsc[F]+FDsc[F]) Div 10+1;
 CX:=X+(W*K) Div 2;
 MY:=YB-YO*K-U*K;
 If (C>=65) And (C<=90) Then Begin End Else MY:=MY-K;
 If (FoldCh(C)>=65) And (FoldCh(C)<=90) Then MY:=YB-YO*K-U*K-K Div 2;
 Case A Of
  1: Line(CX-U*K,MY+U*K,CX+U*K,MY-U*K);
  2: Line(CX-U*K,MY-U*K,CX+U*K,MY+U*K);
  3: Begin Line(CX-U*K,MY+U*K,CX,MY-U*K);Line(CX,MY-U*K,CX+U*K,MY+U*K);End;
  4: Begin
    S:=K*((U+1) Div 2);
    Bar(CX-U*K-S,MY,CX-U*K-1,MY+S-1);Bar(CX+U*K,MY,CX+U*K+S-1,MY+S-1);
   End;
  5: Begin Line(CX,YB,CX,YB+U*K);Line(CX,YB+U*K,CX-K,YB+U*K);End;
  6: Begin
    Line(CX-U*K,MY+K,CX-U*K Div 2,MY);Line(CX-U*K Div 2,MY,CX+U*K Div 2,MY+K);
    Line(CX+U*K Div 2,MY+K,CX+U*K,MY);
   End;
 End;
End;

{ Trace un glyphe : X, YB = ligne de base (ecran), K = agrandissement }
Procedure DrawGlyph(F,C,X,YB,K: Integer);
Var O: LongInt; W,YO,H,Bpr,R,Bx,Run,Y: Integer; B: PBytes; Bit: Boolean;
Begin
 If F>=NFont Then F:=0;
 EnsureFont(F);
 O:=FOff[F]^[C];
 If (C=225) And (FKind[F]=0) Then Begin
  DrawGlyph(F,115,X,YB,K);
  DrawGlyph(F,115,X+FAdv[F]^[115]*K,YB,K);
  Exit;
 End;
 If O=$FFFF Then Exit;
 B:=FBuf[F];
 W:=B^[O+1];YO:=B^[O+2];H:=B^[O+3];
 If YO>127 Then YO:=YO-256;
 If (X>VW) Or (X+W*K<0) Then Exit;
 Bpr:=(W+7) Shr 3;
 For R:=0 To H-1 Do Begin
  Y:=YB-YO*K+R*K;
  If (Y+K<0) Or (Y>VH) Then Continue;
  Run:=-1;
  For Bx:=0 To W-1 Do Begin
   Bit:=(B^[O+4+R*Bpr+(Bx Shr 3)] And ($80 Shr (Bx And 7)))<>0;
   If Bit Then Begin
    If Run<0 Then Run:=Bx;
   End Else If Run>=0 Then Begin
    PlotRun(X+Run*K,X+Bx*K-1,Y,K);Run:=-1;
   End;
  End;
  If Run>=0 Then PlotRun(X+Run*K,X+W*K-1,Y,K);
 End;
 If (C>=128) And (FKind[F]=0) Then DrawAccent(F,C,X,YB,K,W,YO);
End;

{ Largeur d'une chaine dans une police }
Function StrWidthF(F: Integer; Const S: String): Integer;
Var I,W: Integer;
Begin
 W:=0;
 For I:=1 To Length(S) Do W:=W+CharAdv(F,Ord(S[I]));
 StrWidthF:=W;
End;

{ Ecrit une chaine dans une police de document (ecran, coordonnees ecran) }
Procedure DrawStrF(F,X,YTop: Integer; Const S: String);
Var I: Integer;
Begin
 EnsureFont(F);
 SetColor(INK);SetFill(INK);
 For I:=1 To Length(S) Do Begin
  DrawGlyph(F,Ord(S[I]),X,YTop+FAsc[F],1);
  X:=X+CharAdv(F,Ord(S[I]));
 End;
End;

{ ====================================================================== }
{                  BIBLIOTHEQUE D'IMAGES (ARTWORK)                       }
{ ====================================================================== }
{ Les images sont dessinees au demarrage avec les primitives du BGI puis  }
{ stockees en bitmaps monochromes.                                       }

Procedure PBegin;
Begin
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 SetFillStyle(SolidFill,PAPER);
 Bar(0,0,89,89);
 SetColor(INK);
 SetFillStyle(SolidFill,INK);
 SetLineStyle(SolidLn,0,1);
 LastFill:=-1;
End;

Procedure PEnd(Const Nm: String; W,H: Integer);
Var X,Y,Bpr: Integer;
Begin
 If NLib>=MAXLIB Then Exit;
 Inc(NLib);
 Bpr:=(W+7) Shr 3;
 Lib[NLib].Name:=Nm;Lib[NLib].W:=W;Lib[NLib].H:=H;
 GetMem(Lib[NLib].B,Bpr*H);
 FillChar(Lib[NLib].B^,Bpr*H,0);
 For Y:=0 To H-1 Do
  For X:=0 To W-1 Do
   If GetPixel(X,Y)=INK Then
    Lib[NLib].B^[Y*Bpr+(X Shr 3)]:=Lib[NLib].B^[Y*Bpr+(X Shr 3)] Or ($80 Shr (X
      And 7));
 SetLineStyle(SolidLn,0,1);
End;

Procedure Thick(T: Integer);
Begin
 If T>1 Then SetLineStyle(SolidLn,0,ThickWidth) Else SetLineStyle(SolidLn,0,
   NormWidth);
End;

Procedure MakeCouverts;
Var P: Array[1..6] Of PointType;
Begin
 PBegin;
 { fourchette }
 SetLineStyle(SolidLn,0,ThickWidth);
 Line(12,4,12,24);Line(20,4,20,24);Line(28,4,28,24);
 Line(12,24,28,24);
 Line(20,24,20,59);
 { couteau }
 P[1].X:=44;P[1].Y:=4;P[2].X:=54;P[2].Y:=10;P[3].X:=54;P[3].Y:=36;
 P[4].X:=44;P[4].Y:=36;
 SetLineStyle(SolidLn,0,NormWidth);
 FillPoly(4,P);
 SetLineStyle(SolidLn,0,ThickWidth);
 Line(49,36,49,59);
 PEnd('Couverts',64,64);
End;

Procedure MakePoisson;
Var P: Array[1..6] Of PointType; I: Integer;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 Ellipse(28,24,0,360,24,13);
 P[1].X:=50;P[1].Y:=24;P[2].X:=62;P[2].Y:=10;P[3].X:=62;P[3].Y:=38;
 FillPoly(3,P);
 Circle(14,20,3);
 FillEllipse(14,20,1,1);
 Arc(22,24,100,260,10);
 For I:=0 To 3 Do Line(30+I*5,14+I,30+I*5,34-I);
 PEnd('Poisson',64,48);
End;

Procedure MakeEtoile;
Var P: Array[1..10] Of PointType; I: Integer; A,R: Real;
Begin
 PBegin;
 For I:=0 To 9 Do Begin
  A:=-Pi/2+I*Pi/5;
  If Odd(I) Then R:=12 Else R:=29;
  P[I+1].X:=32+Round(R*Cos(A));
  P[I+1].Y:=33+Round(R*Sin(A));
 End;
 SetLineStyle(SolidLn,0,NormWidth);
 SetPat(PatGrey);
 FillPoly(10,P);
 SetColor(INK);
 DrawPoly(10,P);
 Line(P[10].X,P[10].Y,P[1].X,P[1].Y);
 PEnd('Etoile',64,64);
End;

Procedure MakeSoleil;
Var I: Integer; A: Real;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 SetFillStyle(SolidFill,INK);
 FillEllipse(32,32,11,11);
 SetLineStyle(SolidLn,0,ThickWidth);
 For I:=0 To 11 Do Begin
  A:=I*Pi/6;
  Line(32+Round(17*Cos(A)),32+Round(17*Sin(A)),
       32+Round(29*Cos(A)),32+Round(29*Sin(A)));
 End;
 PEnd('Soleil',64,64);
End;

Procedure MakeMaison;
Var P: Array[1..5] Of PointType;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 SetPat(PatHatch);
 P[1].X:=4;P[1].Y:=30;P[2].X:=32;P[2].Y:=6;P[3].X:=60;P[3].Y:=30;
 FillPoly(3,P);
 SetColor(INK);
 Line(4,30,32,6);Line(32,6,60,30);Line(4,30,60,30);
 Rectangle(10,30,54,60);
 Rectangle(26,40,38,60);
 Rectangle(14,36,22,46);Rectangle(42,36,50,46);
 Rectangle(44,10,50,22);
 PEnd('Maison',64,64);
End;

Procedure MakeArbre;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 SetFillStyle(SolidFill,INK);
 Bar(28,40,36,62);
 SetPat(PatDark);
 FillEllipse(32,22,20,17);
 FillEllipse(20,34,14,11);
 FillEllipse(44,34,14,11);
 SetColor(INK);
 Ellipse(32,22,0,360,20,17);
 PEnd('Arbre',64,64);
End;

Procedure MakeCiseaux;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 Ellipse(14,50,0,360,9,11);Ellipse(50,50,0,360,9,11);
 Ellipse(14,50,0,360,5,7);Ellipse(50,50,0,360,5,7);
 SetLineStyle(SolidLn,0,ThickWidth);
 Line(16,40,48,4);Line(48,40,16,4);
 PEnd('Ciseaux',64,64);
End;

Procedure MakeBallon;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 SetPat(PatHatch2);
 FillEllipse(32,22,22,20);
 SetColor(INK);
 Ellipse(32,22,0,360,22,20);
 Ellipse(32,22,0,360,10,20);
 Line(14,34,26,50);Line(50,34,38,50);Line(30,42,28,50);Line(34,42,36,50);
 SetFillStyle(SolidFill,INK);LastFill:=-1;
 Rectangle(24,50,40,60);
 Bar(24,50,40,53);
 PEnd('Ballon',64,64);
End;

Procedure MakeTelephone;
Var P: Array[1..8] Of PointType;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 SetFillStyle(SolidFill,INK);
 Bar(4,36,60,58);
 SetColor(PAPER);
 Rectangle(8,40,56,54);
 SetColor(INK);
 P[1].X:=6;P[1].Y:=36;P[2].X:=4;P[2].Y:=24;P[3].X:=16;P[3].Y:=14;
 P[4].X:=48;P[4].Y:=14;P[5].X:=60;P[5].Y:=24;P[6].X:=58;P[6].Y:=36;
 P[7].X:=48;P[7].Y:=30;P[8].X:=16;P[8].Y:=30;
 SetFillStyle(SolidFill,INK);LastFill:=-1;
 FillPoly(8,P);
 SetColor(PAPER);
 Line(20,45,44,45);Line(20,49,44,49);
 PEnd('Telephone',64,64);
End;

Procedure MakeCoeur;
Var P: Array[1..3] Of PointType;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 SetFillStyle(SolidFill,INK);
 FillEllipse(20,22,14,13);FillEllipse(44,22,14,13);
 P[1].X:=6;P[1].Y:=28;P[2].X:=58;P[2].Y:=28;P[3].X:=32;P[3].Y:=58;
 FillPoly(3,P);
 PEnd('Coeur',64,64);
End;

Procedure MakeFleche;
Var P: Array[1..7] Of PointType;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 P[1].X:=2;P[1].Y:=22;P[2].X:=36;P[2].Y:=22;P[3].X:=36;P[3].Y:=6;
 P[4].X:=62;P[4].Y:=32;P[5].X:=36;P[5].Y:=58;P[6].X:=36;P[6].Y:=42;
 P[7].X:=2;P[7].Y:=42;
 SetPat(PatGrey);
 FillPoly(7,P);
 SetColor(INK);
 DrawPoly(7,P);
 Line(P[7].X,P[7].Y,P[1].X,P[1].Y);
 PEnd('Fleche',64,64);
End;

Procedure MakeJournal;
Var I: Integer;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 Rectangle(4,4,60,60);
 SetFillStyle(SolidFill,INK);
 Bar(8,8,56,18);
 SetColor(PAPER);
 Line(12,13,52,13);
 SetColor(INK);
 Rectangle(8,22,26,40);
 Line(8,22,26,40);Line(26,22,8,40);
 For I:=0 To 3 Do Line(30,24+I*5,56,24+I*5);
 For I:=0 To 3 Do Line(8,44+I*4,56,44+I*4);
 PEnd('Journal',64,64);
End;

Procedure MakeTasse;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 Ellipse(26,24,0,360,20,5);
 Line(6,24,10,50);Line(46,24,42,50);
 Ellipse(26,50,180,360,16,5);
 Ellipse(26,50,0,180,16,5);
 SetLineStyle(SolidLn,0,ThickWidth);
 Arc(48,34,270,90,8);
 SetLineStyle(SolidLn,0,NormWidth);
 SetFillStyle(SolidFill,INK);
 Line(16,4,18,14);Line(26,2,24,14);Line(36,4,34,14);
 PEnd('Tasse',64,64);
End;

Procedure MakeLivre;
Var P: Array[1..4] Of PointType; I: Integer;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 P[1].X:=4;P[1].Y:=14;P[2].X:=32;P[2].Y:=20;P[3].X:=32;P[3].Y:=58;P[4].X:=4;
   P[4].Y:=52;
 DrawPoly(4,P);Line(4,52,4,14);
 P[1].X:=60;P[1].Y:=14;P[2].X:=32;P[2].Y:=20;P[3].X:=32;P[3].Y:=58;P[4].X:=60;
   P[4].Y:=52;
 DrawPoly(4,P);Line(60,52,60,14);
 For I:=0 To 4 Do Begin
  Line(8,24+I*6,28,28+I*6);Line(56,24+I*6,36,28+I*6);
 End;
 PEnd('Livre',64,64);
End;

Procedure BuildLibrary;
Begin
 NLib:=0;
 MakeCouverts;MakePoisson;MakeEtoile;MakeSoleil;MakeMaison;MakeArbre;
 MakeCiseaux;MakeBallon;MakeTelephone;MakeCoeur;MakeFleche;MakeJournal;
 MakeTasse;MakeLivre;
End;

{ Bit (X,Y) de l'image L }
Function PieceBit(L,X,Y: Integer): Boolean;
Var Bpr: Integer;
Begin
 PieceBit:=False;
 If (L<1) Or (L>NLib) Then Exit;
 If (X<0) Or (Y<0) Or (X>=Lib[L].W) Or (Y>=Lib[L].H) Then Exit;
 Bpr:=(Lib[L].W+7) Shr 3;
 PieceBit:=(Lib[L].B^[Y*Bpr+(X Shr 3)] And ($80 Shr (X And 7)))<>0;
End;

{ Dessine la zone source (SX1,SY1,SX2,SY2) de l'image L dans le rectangle
  ecran DX,DY,DW,DH (coordonnees relatives a la fenetre courante) }
Procedure DrawPiece(L,SX1,SY1,SX2,SY2: Integer; FlH,FlV: Boolean;
                    DX,DY,DW,DH: LongInt);
Var X,Y,X1,X2,Y1,Y2,Run: LongInt; SX,SY,SW,SHt: LongInt; Bit: Boolean;
Begin
 If (DW<=0) Or (DH<=0) Then Exit;
 SW:=SX2-SX1;SHt:=SY2-SY1;
 If (SW<=0) Or (SHt<=0) Then Exit;
 X1:=Max2(DX,0);X2:=Min2(DX+DW-1,VW-1);
 Y1:=Max2(DY,0);Y2:=Min2(DY+DH-1,VH-1);
 If (X1>X2) Or (Y1>Y2) Then Exit;
 SetColor(INK);
 For Y:=Y1 To Y2 Do Begin
  SY:=((Y-DY)*SHt) Div DH;
  If FlV Then SY:=SHt-1-SY;
  SY:=SY+SY1;
  Run:=-1;
  For X:=X1 To X2 Do Begin
   SX:=((X-DX)*SW) Div DW;
   If FlH Then SX:=SW-1-SX;
   SX:=SX+SX1;
   Bit:=PieceBit(L,SX,SY);
   If Bit Then Begin
    If Run<0 Then Run:=X;
   End Else If Run>=0 Then Begin
    Line(Run,Y,X-1,Y);Run:=-1;
   End;
  End;
  If Run>=0 Then Line(Run,Y,X2,Y);
 End;
End;

{ Motif de remplissage numero I (0 aucun, 1 blanc, 11 noir) }
Procedure FillPat(I: Integer; X1,Y1,X2,Y2: Integer);
Begin
 If I=0 Then Exit;
 If I=1 Then Begin Box(X1,Y1,X2,Y2,PAPER);Exit;End;
 If I=11 Then Begin Box(X1,Y1,X2,Y2,INK);Exit;End;
 Case I Of
  2: SetPat(PatDots);
  3: SetPat(PatLight);
  4: SetPat(PatGrey);
  5: SetPat(PatDark);
  6: SetPat(PatHatch);
  7: SetPat(PatHatch2);
  8: SetPat(PatHoriz);
  9: SetPat(PatVert);
  10: SetPat(PatGrid);
 End;
 Bar(X1,Y1,X2,Y2);
End;

{ ====================================================================== }
{                      HISTOIRES (flux de texte)                         }
{ ====================================================================== }
{ Histoire 0 : texte principal ; 1..MAXPG : titre de chaque page.        }
{ Un CR est toujours present en fin de texte (position Len).             }

Procedure StInit(I,ACap,Fn,Al: Integer);
Begin
 St[I].Cap:=ACap;
 GetMem(St[I].T,ACap+2);GetMem(St[I].F,ACap+2);GetMem(St[I].A,ACap+2);
 FillChar(St[I].T^,ACap+2,0);FillChar(St[I].F^,ACap+2,0);FillChar(St[I].A^,
   ACap+2,0);
 St[I].Len:=0;
 St[I].T^[0]:=13;St[I].F^[0]:=Fn;St[I].A^[0]:=Al;
End;

Procedure StClear(I,Fn,Al: Integer);
Begin
 St[I].Len:=0;
 St[I].T^[0]:=13;St[I].F^[0]:=Fn;St[I].A^[0]:=Al;
End;

Function StIns(S,Ps: Integer; Ch,Fn,Al: Byte): Boolean;
Var N: Integer;
Begin
 StIns:=False;
 If St[S].Len>=St[S].Cap Then Exit;
 N:=St[S].Len-Ps+1;
 Move(St[S].T^[Ps],St[S].T^[Ps+1],N);
 Move(St[S].F^[Ps],St[S].F^[Ps+1],N);
 Move(St[S].A^[Ps],St[S].A^[Ps+1],N);
 St[S].T^[Ps]:=Ch;St[S].F^[Ps]:=Fn;St[S].A^[Ps]:=Al;
 Inc(St[S].Len);
 StIns:=True;
End;

Procedure StDel(S,P1,P2: Integer);
Var N: Integer;
Begin
 If P2>St[S].Len Then P2:=St[S].Len;
 If P1>=P2 Then Exit;
 N:=St[S].Len-P2+1;
 Move(St[S].T^[P2],St[S].T^[P1],N);
 Move(St[S].F^[P2],St[S].F^[P1],N);
 Move(St[S].A^[P2],St[S].A^[P1],N);
 Dec(St[S].Len,P2-P1);
End;

Function ParaEndPos(S,Ps: Integer): Integer;
Begin
 While (Ps<St[S].Len) And (St[S].T^[Ps]<>13) Do Inc(Ps);
 ParaEndPos:=Ps;
End;

Function ParaStartPos(S,Ps: Integer): Integer;
Begin
 While (Ps>0) And (St[S].T^[Ps-1]<>13) Do Dec(Ps);
 ParaStartPos:=Ps;
End;

Procedure StAppend(S: Integer; Const Tx: String; Fn: Byte);
Var I: Integer;
Begin
 For I:=1 To Length(Tx) Do
  If Tx[I]=#13 Then StIns(S,St[S].Len,13,Fn,St[S].A^[St[S].Len])
  Else StIns(S,St[S].Len,Ord(Tx[I]),Fn,0);
End;

Function SelRange(Var A,B: Integer): Boolean;
Begin
 SelRange:=False;
 If SelA<0 Then Exit;
 If SelA<Cur Then Begin A:=SelA;B:=Cur;End Else Begin A:=Cur;B:=SelA;End;
 SelRange:=A<B;
End;

{ ---- annulation (un niveau) ---- }
Procedure PushUndo;
Var N: Integer;
Begin
 If UndoT=Nil Then Exit;
 N:=St[ASt].Len+1;
 If N>St[0].Cap+2 Then Exit;
 Move(St[ASt].T^,UndoT^,N);Move(St[ASt].F^,UndoF^,N);Move(St[ASt].A^,UndoA^,N);
 UndoLen:=St[ASt].Len;UndoCur:=Cur;UndoSt:=ASt;UndoOK:=True;
End;

Procedure Relayout; Forward;

Procedure DoUndo;
Var N: Integer;
Begin
 If Not UndoOK Then Exit;
 N:=UndoLen+1;
 Move(UndoT^,St[UndoSt].T^,N);Move(UndoF^,St[UndoSt].F^,N);Move(UndoA^,
   St[UndoSt].A^,N);
 St[UndoSt].Len:=UndoLen;
 ASt:=UndoSt;Cur:=UndoCur;SelA:=-1;
 UndoOK:=False;
 Modified:=True;
 Relayout;
End;

{ ====================================================================== }
{                   MISE EN PAGE : REGIONS ET HABILLAGE                  }
{ ====================================================================== }

Const
 LEAD   = 1;
 MAXIV  = 8;
 MAXLX  = 520;

Var
 IvA,IvB   : Array[1..MAXIV] Of Integer;
 NIv       : Integer;
 BandOn    : Boolean;
 BandR,BandY,BandH,BandNext,BandN : Integer;
 BandA,BandB : Array[1..MAXIV] Of Integer;
 LX        : Array[0..MAXLX] Of Integer;
 LXn       : Integer;

Procedure BuildRegions;
Var P,C,N,CW,Y0: Integer;
Begin
 NReg:=0;
 For P:=1 To NPg Do Begin
  N:=NCol[P];
  CW:=(PGW-2*MRG-(N-1)*COLGAP) Div N;
  If HasHead[P] Then Y0:=MRG+HEADH+10 Else Y0:=MRG;
  For C:=0 To N-1 Do Begin
   Inc(NReg);
   RegPg[NReg]:=P;RegX[NReg]:=MRG+C*(CW+COLGAP);RegY[NReg]:=Y0;
   RegW[NReg]:=CW;RegH[NReg]:=PGH-MRG-Y0;
  End;
 End;
End;

Procedure SortIv;
Var I,J,T: Integer;
Begin
 For I:=1 To NIv-1 Do
  For J:=I+1 To NIv Do
   If IvA[J]<IvA[I] Then Begin
    T:=IvA[I];IvA[I]:=IvA[J];IvA[J]:=T;
    T:=IvB[I];IvB[I]:=IvB[J];IvB[J]:=T;
   End;
End;

Procedure CutIv(OL,OR_: Integer);
Var K,A,B: Integer; N0: Integer;
Begin
 N0:=NIv;
 For K:=1 To N0 Do Begin
  A:=IvA[K];B:=IvB[K];
  If (OR_<=A) Or (OL>=B) Then Continue;
  If (OL<=A) And (OR_>=B) Then Begin IvB[K]:=IvA[K];End
  Else If (OL>A) And (OR_<B) Then Begin
   IvB[K]:=OL;
   If NIv<MAXIV Then Begin Inc(NIv);IvA[NIv]:=OR_;IvB[NIv]:=B;End;
  End
  Else If OL<=A Then IvA[K]:=OR_
  Else IvB[K]:=OL;
 End;
End;

{ Intervalles libres d'une bande. Retourne False si l'on doit descendre
  (NewY = ordonnee de reprise) }
Function BandIntervals(PgN,X0,W,Y,H: Integer; Var NewY: Integer): Boolean;
Var I,K,N,MinW,OT,OB,OL,OR_,Bot: Integer; Blocked: Boolean;
Begin
 NIv:=1;IvA[1]:=X0;IvB[1]:=X0+W;
 Blocked:=False;Bot:=32000;BandIntervals:=True;
 For I:=1 To NArt Do
  If (Arts[I].Pg=PgN) And (Arts[I].Flow<>FL_OVER) Then Begin
   OT:=Arts[I].Y-PAD;OB:=Arts[I].Y+Arts[I].H+PAD;
   OL:=Arts[I].X-PAD;OR_:=Arts[I].X+Arts[I].W+PAD;
   If (Y<OB) And (Y+H>OT) And (OR_>X0) And (OL<X0+W) Then Begin
    If OB<Bot Then Bot:=OB;
    Case Arts[I].Flow Of
     FL_CLEAR: Begin NewY:=OB;BandIntervals:=False;Exit;End;
     FL_BOTH: CutIv(OL,OR_);
     FL_LEFT: For K:=1 To NIv Do If IvB[K]>OL Then IvB[K]:=OL;
     FL_RIGHT: For K:=1 To NIv Do If IvA[K]<OR_ Then IvA[K]:=OR_;
    End;
    Blocked:=True;
   End;
  End;
 MinW:=MINSLOT;
 If MinW>W Div 2 Then MinW:=W Div 2;
 N:=0;
 For K:=1 To NIv Do
  If IvB[K]-IvA[K]>=MinW Then Begin
   Inc(N);IvA[N]:=IvA[K];IvB[N]:=IvB[K];
  End;
 NIv:=N;
 SortIv;
 If (NIv=0) And Blocked Then Begin NewY:=Bot;BandIntervals:=False;End
 Else If NIv=0 Then Begin NIv:=1;IvA[1]:=X0;IvB[1]:=X0+W;End;
End;

{ Trouve une bande libre de hauteur H a partir de (R,Y) }
Function FindBand(Var R,Y: Integer; H: Integer): Boolean;
Var NewY,K,Guard: Integer;
Begin
 FindBand:=False;
 Guard:=0;
 While R<=NReg Do Begin
  Inc(Guard);
  If Guard>400 Then Begin R:=NReg+1;Exit;End;
  If (Y+H>RegY[R]+RegH[R]) And (Y>RegY[R]) Then Begin
   Inc(R);
   If R<=NReg Then Y:=RegY[R];
   Continue;
  End;
  NewY:=Y+4;
  If BandIntervals(RegPg[R],RegX[R],RegW[R],Y,H,NewY) Then Begin
   BandR:=R;BandY:=Y;BandH:=H;BandN:=NIv;BandNext:=2;BandOn:=True;
   For K:=1 To NIv Do Begin BandA[K]:=IvA[K];BandB[K]:=IvB[K];End;
   FindBand:=True;
   Exit;
  End;
  If NewY<=Y Then NewY:=Y+1;
  Y:=NewY;
 End;
End;

{ Remplit une ligne a partir de Ps dans une largeur W }
Procedure FillLine(S,Ps,W: Integer; Var E,Nx,Lw,Ns,Asc,Dsc: Integer; Var
  ParaEnd: Boolean);
Var I,X,Adv,LastSp,F,K: Integer; C: Byte;
Begin
 I:=Ps;X:=0;LastSp:=-1;ParaEnd:=False;
 E:=Ps;Nx:=Ps;
 While True Do Begin
  C:=St[S].T^[I];
  If C=13 Then Begin
   E:=I;Nx:=I+1;ParaEnd:=True;Break;
  End;
  Adv:=CharAdv(St[S].F^[I],C);
  If (X+Adv>W) And (I>Ps) Then Begin
   If LastSp>=Ps Then Begin E:=LastSp;Nx:=LastSp+1;End
   Else Begin E:=I;Nx:=I;End;
   Break;
  End;
  If C=32 Then LastSp:=I;
  X:=X+Adv;
  Inc(I);
 End;
 { retire les espaces terminaux, saute ceux qui suivent la coupure }
 While (E>Ps) And (St[S].T^[E-1]=32) Do Dec(E);
 If Not ParaEnd Then
  While (Nx<St[S].Len) And (St[S].T^[Nx]=32) Do Inc(Nx);
 Lw:=0;Ns:=0;Asc:=0;Dsc:=0;
 For K:=Ps To E-1 Do Begin
  F:=St[S].F^[K];
  Lw:=Lw+CharAdv(F,St[S].T^[K]);
  If St[S].T^[K]=32 Then Inc(Ns);
  If FAsc[F]>Asc Then Asc:=FAsc[F];
  If FDsc[F]>Dsc Then Dsc:=FDsc[F];
 End;
 If E=Ps Then Begin
  F:=St[S].F^[Ps];
  Asc:=FAsc[F];Dsc:=FDsc[F];
 End;
End;

Procedure AddLine(S,PgN,Ps,E,Nx,X,Y,W,H,Asc,Lw,Ns: Integer; ParaEnd: Boolean);
Var PE: Integer;
Begin
 If NLn>=MAXLINE Then Exit;
 Lines^[NLn].S:=Ps;Lines^[NLn].E:=E;Lines^[NLn].Nx:=Nx;
 Lines^[NLn].X:=X;Lines^[NLn].Y:=Y;Lines^[NLn].W:=W;Lines^[NLn].H:=H;
 Lines^[NLn].Asc:=Asc;Lines^[NLn].Lw:=Lw;Lines^[NLn].Ns:=Ns;
 Lines^[NLn].Sty:=S;Lines^[NLn].Pg:=PgN;
 PE:=ParaEndPos(S,Ps);
 Lines^[NLn].Al:=St[S].A^[PE];
 If ParaEnd Then Lines^[NLn].Fl:=1 Else Lines^[NLn].Fl:=0;
 Inc(NLn);
End;

Procedure LayoutHead(P: Integer);
Var Ps,Y,E,Nx,Lw,Ns,Asc,Dsc,H,First,I,Tot: Integer; PEnd: Boolean;
Begin
 Ps:=0;Y:=MRG;First:=NLn;
 While (Ps<=St[P].Len) And (NLn<MAXLINE) Do Begin
  FillLine(P,Ps,PGW-2*MRG,E,Nx,Lw,Ns,Asc,Dsc,PEnd);
  H:=Asc+Dsc+LEAD;
  If (Y+H>MRG+HEADH) And (NLn>First) Then Break;
  AddLine(P,P,Ps,E,Nx,MRG,Y,PGW-2*MRG,H,Asc,Lw,Ns,PEnd);
  Y:=Y+H;Ps:=Nx;
 End;
 Tot:=Y-MRG;
 If Tot<HEADH Then
  For I:=First To NLn-1 Do Lines^[I].Y:=Lines^[I].Y+(HEADH-Tot) Div 2;
End;

Procedure LayoutFlow;
Var Ps,R,Y,E,Nx,Lw,Ns,Asc,Dsc,Hd,H2,Tries,SX,SW,LY,LH,F0: Integer; PEnd,Ok:
  Boolean;
Begin
 Ps:=0;R:=1;Y:=RegY[1];BandOn:=False;Overflow:=False;
 SX:=0;SW:=100;LY:=0;LH:=10;
 While (Ps<=St[0].Len) And (NLn<MAXLINE) Do Begin
  F0:=St[0].F^[Ps];
  If BandOn And (BandNext<=BandN) Then Begin
   SX:=BandA[BandNext];SW:=BandB[BandNext]-SX;LY:=BandY;LH:=BandH;
   Inc(BandNext);
   FillLine(0,Ps,SW,E,Nx,Lw,Ns,Asc,Dsc,PEnd);
  End Else Begin
   If BandOn Then Y:=BandY+BandH;
   BandOn:=False;
   Hd:=FAsc[F0]+FDsc[F0]+LEAD;
   Tries:=0;
   Repeat
    Ok:=FindBand(R,Y,Hd);
    If Not Ok Then Break;
    SX:=BandA[1];SW:=BandB[1]-SX;
    FillLine(0,Ps,SW,E,Nx,Lw,Ns,Asc,Dsc,PEnd);
    H2:=Asc+Dsc+LEAD;
    Inc(Tries);
    If (H2>Hd) And (Tries<4) Then Begin Hd:=H2;BandOn:=False;End
    Else Break;
   Until False;
   If Not Ok Then Begin Overflow:=True;Break;End;
   LY:=BandY;LH:=Integer(Max2(BandH,Asc+Dsc+LEAD));
  End;
  AddLine(0,RegPg[BandR],Ps,E,Nx,SX,LY,SW,LH,Asc,Lw,Ns,PEnd);
  Ps:=Nx;
 End;
 If Ps<=St[0].Len Then Overflow:=True;
End;

Procedure AddPageAuto;
Begin
 If NPg>=MAXPG Then Exit;
 Inc(NPg);
 NCol[NPg]:=NCol[NPg-1];HasHead[NPg]:=False;
 StClear(NPg,DefHead,AL_CENTER);
End;

Procedure LayoutAll;
Var P,Guard: Integer;
Begin
 Guard:=0;
 Repeat
  NLn:=0;
  BuildRegions;
  For P:=1 To NPg Do If HasHead[P] Then LayoutHead(P);
  LayoutFlow;
  Inc(Guard);
  If Overflow And (NPg<MAXPG) And (Guard<MAXPG+2) Then AddPageAuto
  Else Break;
 Until False;
End;

Procedure Relayout;
Begin
 LayoutAll;
 NeedDraw:=True;
End;

{ ---- lignes et positions ---- }

Function LineOfPos(S,Ps: Integer): Integer;
Var I,B: Integer;
Begin
 B:=-1;
 For I:=0 To NLn-1 Do
  If Lines^[I].Sty=S Then
   If Lines^[I].S<=Ps Then B:=I;
 If B>=0 Then
  If (Ps>=Lines^[B].Nx) And (Lines^[B].Nx<=St[S].Len) Then B:=-1;
 LineOfPos:=B;
End;

{ Positions horizontales des caracteres de la ligne I (points de page) }
Procedure LineXs(I: Integer);
Var K,X0,Ex,Per,Rem_,SpI,Adv,N: Integer; S: Integer;
Begin
 S:=Lines^[I].Sty;
 N:=Lines^[I].E-Lines^[I].S;
 If N>MAXLX-1 Then N:=MAXLX-1;
 Ex:=0;Per:=0;Rem_:=0;
 Case Lines^[I].Al Of
  AL_RIGHT: X0:=Lines^[I].X+Lines^[I].W-Lines^[I].Lw;
  AL_CENTER: X0:=Lines^[I].X+(Lines^[I].W-Lines^[I].Lw) Div 2;
 Else
  X0:=Lines^[I].X;
 End;
 If (Lines^[I].Al=AL_BOTH) And (Lines^[I].Fl=0) And (Lines^[I].Ns>0) Then Begin
  Ex:=Lines^[I].W-Lines^[I].Lw;
  If Ex<0 Then Ex:=0;
  Per:=Ex Div Lines^[I].Ns;Rem_:=Ex Mod Lines^[I].Ns;
 End;
 SpI:=0;
 For K:=0 To N-1 Do Begin
  LX[K]:=X0;
  Adv:=CharAdv(St[S].F^[Lines^[I].S+K],St[S].T^[Lines^[I].S+K]);
  X0:=X0+Adv;
  If St[S].T^[Lines^[I].S+K]=32 Then Begin
   X0:=X0+Per;
   If SpI<Rem_ Then Inc(X0);
   Inc(SpI);
  End;
 End;
 LX[N]:=X0;
 LXn:=N;
End;

{ Position dans le texte pour l'abscisse Xp (points de page) sur la ligne I }
Function PosAtX(I,Xp: Integer): Integer;
Var K: Integer;
Begin
 LineXs(I);
 K:=0;
 While (K<LXn) And (Xp>=(LX[K]+LX[K+1]) Div 2) Do Inc(K);
 PosAtX:=Lines^[I].S+K;
End;

{ Abscisse (points de page) de la position Ps sur la ligne I }
Function XOfPos(I,Ps: Integer): Integer;
Var K: Integer;
Begin
 LineXs(I);
 K:=Ps-Lines^[I].S;
 If K<0 Then K:=0;
 If K>LXn Then K:=LXn;
 XOfPos:=LX[K];
End;

{ ====================================================================== }
{                  GEOMETRIE DE LA VUE (points <-> pixels)               }
{ ====================================================================== }

Var
 OrgX,OrgY0 : LongInt;           { origine de la page 1 dans la fenetre }
 CaretX,CaretY1,CaretY2 : Integer;
 CaretShown : Boolean;

Function Sc(V: LongInt): LongInt;
Begin
 Sc:=V*ZN Div ZD;
End;

Function Greek: Boolean;
Begin
 Greek:=ZD>1;
End;

Function StrideP: LongInt;
Begin
 StrideP:=Sc(PGH+PGGAP);
End;

Function DocWpx: LongInt;
Begin
 DocWpx:=Sc(PGW)+12;
End;

Function DocHpx: LongInt;
Begin
 DocHpx:=LongInt(NPg)*StrideP+12;
End;

Procedure ClampScroll;
Begin
 If ScrX>DocWpx-VW Then ScrX:=DocWpx-VW;
 If ScrX<0 Then ScrX:=0;
 If ScrY>DocHpx-VH Then ScrY:=DocHpx-VH;
 If ScrY<0 Then ScrY:=0;
End;

Procedure CalcOrg;
Begin
 ClampScroll;
 If DocWpx<VW Then OrgX:=(VW-Sc(PGW)) Div 2 Else OrgX:=6-ScrX;
 OrgY0:=6-ScrY;
End;

Function PgY0(P: Integer): LongInt;
Begin
 PgY0:=OrgY0+LongInt(P-1)*StrideP;
End;

{ Position document (page P, point lx,ly) -> ecran (relatif a la fenetre) }
Procedure PageToScr(P: Integer; LX_,LY_: LongInt; Var SX,SY: LongInt);
Begin
 SX:=OrgX+Sc(LX_);
 SY:=PgY0(P)+Sc(LY_);
End;

{ Ecran -> page et points de page (la page la plus proche) }
Function ScrToPage(X,Y: LongInt; Var P: Integer; Var LX_,LY_: LongInt): Boolean;
Var I: Integer;
Begin
 ScrToPage:=False;
 P:=1;
 For I:=1 To NPg Do
  If Y>=PgY0(I)-Sc(PGGAP) Div 2 Then P:=I;
 LX_:=(X-OrgX)*ZD Div ZN;
 LY_:=(Y-PgY0(P))*ZD Div ZN;
 ScrToPage:=(LX_>=0) And (LX_<PGW) And (LY_>=0) And (LY_<PGH);
End;

Function ArtOnPage(Pg,X,Y: Integer): Integer;
Var I: Integer;
Begin
 ArtOnPage:=0;
 For I:=NArt DownTo 1 Do
  If (Arts[I].Pg=Pg) And (X>=Arts[I].X-2) And (X<=Arts[I].X+Arts[I].W+2) And
     (Y>=Arts[I].Y-2) And (Y<=Arts[I].Y+Arts[I].H+2) Then Begin
   ArtOnPage:=I;Exit;
  End;
End;

{ ====================================================================== }
{                          DESSIN DES PAGES                              }
{ ====================================================================== }

Procedure DrawPageBase(X0,Y0: LongInt);
Var X1,Y1: LongInt;
Begin
 X1:=X0+Sc(PGW)-1;Y1:=Y0+Sc(PGH)-1;
 Box(X0+4,Y0+4,X1+4,Y1+4,INK);
 Box(X0-3,Y0-3,X1+3,Y1+3,PAPER);
 Frame(X0-3,Y0-3,X1+3,Y1+3);
 Frame(X0-1,Y0-1,X1+1,Y1+1);
End;

Procedure XorLine(X1,Y,X2: Integer);
Begin
 SetWriteMode(XORPut);
 SetColor(PAPER);
 SetLineStyle(SolidLn,0,1);
 Line(X1,Y,X2,Y);
 SetWriteMode(NormalPut);
End;

Procedure XorRect(X1,Y1,X2,Y2: Integer);
Var Y: Integer;
Begin
 If Y1<0 Then Y1:=0;
 If Y2>VH Then Y2:=VH;
 SetWriteMode(XORPut);
 SetColor(PAPER);
 SetLineStyle(SolidLn,0,1);
 For Y:=Y1 To Y2 Do Line(X1,Y,X2,Y);
 SetWriteMode(NormalPut);
End;

Procedure DotRect(X1,Y1,X2,Y2: Integer);
Begin
 SetColor(INK);
 SetLineStyle(UserBitLn,$AAAA,1);
 Rectangle(X1,Y1,X2,Y2);
 SetLineStyle(SolidLn,0,1);
End;

{ Ligne de texte "grisee" (vues reduites) }
Procedure DrawGreekLine(I: Integer; X0,Y0: LongInt);
Var XS,XE,YT,H,Fh: LongInt; F: Integer;
Begin
 If Lines^[I].E<=Lines^[I].S Then Exit;
 Case Lines^[I].Al Of
  AL_RIGHT: XS:=Lines^[I].X+Lines^[I].W-Lines^[I].Lw;
  AL_CENTER: XS:=Lines^[I].X+(Lines^[I].W-Lines^[I].Lw) Div 2;
 Else
  XS:=Lines^[I].X;
 End;
 XE:=XS+Lines^[I].Lw;
 If (Lines^[I].Al=AL_BOTH) And (Lines^[I].Fl=0) Then Begin XS:=Lines^[I].X;
   XE:=XS+Lines^[I].W;End;
 F:=St[Lines^[I].Sty].F^[Lines^[I].S];
 Fh:=FAsc[F]+FDsc[F];
 YT:=Y0+Sc(Lines^[I].Y+Lines^[I].Asc-FAsc[F]*7 Div 10);
 H:=Sc(Fh*7 Div 10);
 If H<1 Then H:=1;
 If H>=3 Then Begin
  If Fh>=20 Then PatBar(X0+Sc(XS),YT,X0+Sc(XE),YT+H-1,PatDark)
  Else PatBar(X0+Sc(XS),YT,X0+Sc(XE),YT+H-1,PatGrey);
 End Else Begin
  SetColor(INK);
  SetLineStyle(UserBitLn,$AAAA,1);
  Line(X0+Sc(XS),YT,X0+Sc(XE),YT);
  SetLineStyle(SolidLn,0,1);
 End;
End;

Procedure DrawTextLine(I: Integer; X0,Y0: LongInt);
Var K,J,S,Sa,Sb,A,B,X1,X2: Integer; YB,YT: LongInt; C: Byte;
Begin
 S:=Lines^[I].Sty;
 K:=ZN;
 LineXs(I);
 YB:=Y0+(Lines^[I].Y+Lines^[I].Asc)*K;
 YT:=Y0+Lines^[I].Y*K;
 SetColor(INK);SetFill(INK);
 For J:=Lines^[I].S To Lines^[I].E-1 Do Begin
  C:=St[S].T^[J];
  If C<>32 Then DrawGlyph(St[S].F^[J],C,X0+LX[J-Lines^[I].S]*K,YB,K);
 End;
 If (S=ASt) And SelRange(Sa,Sb) Then Begin
  A:=Sa;B:=Sb;
  If A<Lines^[I].S Then A:=Lines^[I].S;
  If B>Lines^[I].Nx Then B:=Lines^[I].Nx;
  If A<B Then Begin
   X1:=A-Lines^[I].S;
   If X1>LXn Then X1:=LXn;
   If B>Lines^[I].E Then Begin
    X2:=LXn;
    X1:=X1;
    XorRect(X0+LX[X1]*K,YT,X0+LX[X2]*K+K*3,YT+Lines^[I].H*K-1);
   End Else Begin
    X2:=B-Lines^[I].S;
    XorRect(X0+LX[X1]*K,YT,X0+LX[X2]*K-1,YT+Lines^[I].H*K-1);
   End;
  End;
 End;
End;

Procedure DrawLinesOfPage(P: Integer; X0,Y0: LongInt);
Var I: Integer; YT,YE: LongInt;
Begin
 For I:=0 To NLn-1 Do
  If Lines^[I].Pg=P Then Begin
   YT:=Y0+Sc(Lines^[I].Y);YE:=YT+Sc(Lines^[I].H+4);
   If (YE<0) Or (YT>VH) Then Continue;
   If Greek Then DrawGreekLine(I,X0,Y0) Else DrawTextLine(I,X0,Y0);
  End;
End;

Procedure DrawArtItem(I: Integer; X0,Y0: LongInt; Sel: Boolean);
Var SX,SY,SW,SH,T,J,TT: LongInt;
Begin
 SX:=X0+Sc(Arts[I].X);SY:=Y0+Sc(Arts[I].Y);
 SW:=Sc(Arts[I].W);SH:=Sc(Arts[I].H);
 If SW<1 Then SW:=1;
 If SH<1 Then SH:=1;
 Case Arts[I].Kind Of
  AR_ART: DrawPiece(Arts[I].Lib,Arts[I].SX1,Arts[I].SY1,Arts[I].SX2,Arts[I].SY2,
                    Arts[I].FH<>0,Arts[I].FV<>0,SX,SY,SW,SH);
  AR_BOX: Begin
    FillPat(Arts[I].Pat,SX,SY,SX+SW-1,SY+SH-1);
    T:=Sc(Arts[I].Th);
    If (T<1) And (Arts[I].Th>0) Then T:=1;
    SetColor(INK);SetLineStyle(SolidLn,0,1);
    For J:=0 To T-1 Do
     If (SW-1-2*J>0) And (SH-1-2*J>0) Then Rectangle(SX+J,SY+J,SX+SW-1-J,
       SY+SH-1-J);
   End;
  AR_LINE: Begin
    T:=Sc(Arts[I].Th);
    If T<1 Then T:=1;
    SetColor(INK);SetLineStyle(SolidLn,0,1);
    For J:=0 To T-1 Do Begin
     TT:=J-T Div 2;
     If SW>=SH Then Begin
      If Arts[I].FV=0 Then Line(SX,SY+TT,SX+SW-1,SY+SH-1+TT)
      Else Line(SX,SY+SH-1+TT,SX+SW-1,SY+TT);
     End Else Begin
      If Arts[I].FV=0 Then Line(SX+TT,SY,SX+SW-1+TT,SY+SH-1)
      Else Line(SX+TT,SY+SH-1,SX+SW-1+TT,SY);
     End;
    End;
   End;
 End;
 If Sel Then DotRect(SX-2,SY-2,SX+SW+1,SY+SH+1);
End;

Procedure DrawColumnGuides(P: Integer; X0,Y0: LongInt);
Var R: Integer;
Begin
 For R:=1 To NReg Do
  If RegPg[R]=P Then
   DotRect(X0+Sc(RegX[R]),Y0+Sc(RegY[R]),X0+Sc(RegX[R]+RegW[R]),
     Y0+Sc(RegY[R]+RegH[R]));
 If HasHead[P] Then
  DotRect(X0+Sc(MRG),Y0+Sc(MRG),X0+Sc(PGW-MRG),Y0+Sc(MRG+HEADH));
End;

{ Page complete : fond, texte, images }
Procedure DrawPageFull(P: Integer; X0,Y0: LongInt; Guides: Boolean);
Var I: Integer;
Begin
 DrawPageBase(X0,Y0);
 If Guides Then DrawColumnGuides(P,X0,Y0);
 DrawLinesOfPage(P,X0,Y0);
 For I:=1 To NArt Do
  If Arts[I].Pg=P Then DrawArtItem(I,X0,Y0,(I=SelArt) And (Mode=MD_ART));
End;

{ ---- curseur de texte et d'images ---- }

Procedure CaretGeom(Var Ok: Boolean);
Var I,K: Integer; X0,Y0: LongInt;
Begin
 Ok:=False;
 If (Mode<>MD_TEXT) Or Greek Then Exit;
 I:=LineOfPos(ASt,Cur);
 If I<0 Then Exit;
 K:=ZN;
 X0:=OrgX;Y0:=PgY0(Lines^[I].Pg);
 CaretX:=Integer(X0+XOfPos(I,Cur)*K);
 CaretY1:=Integer(Y0+Lines^[I].Y*K);
 CaretY2:=CaretY1+Lines^[I].H*K-1;
 Ok:=(CaretY2>=0) And (CaretY1<=VH);
End;

Procedure ToggleCaret;
Var Ok: Boolean;
Begin
 CaretGeom(Ok);
 If Not Ok Then Exit;
 SetViewPort(0,MENU_H+1,SCR_W-1,PANEL_Y-1,True);
 SetWriteMode(XORPut);
 SetColor(PAPER);
 SetLineStyle(SolidLn,0,1);
 Line(CaretX,CaretY1,CaretX,CaretY2);
 Line(CaretX+1,CaretY1,CaretX+1,CaretY2);
 SetWriteMode(NormalPut);
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 CaretOn:=Not CaretOn;
End;

{ Convertit une position document (x,y absolus) en page + coordonnees }
Procedure DocToPage(DX,DY: LongInt; Var P: Integer; Var LX_,LY_: LongInt);
Begin
 P:=Integer(DY Div (PGH+PGGAP))+1;
 If P<1 Then P:=1;
 If P>NPg Then P:=NPg;
 LX_:=DX;
 LY_:=DY-LongInt(P-1)*(PGH+PGGAP);
End;

Procedure DrawArtCursor;
Var P: Integer; LX_,LY_,SX,SY: LongInt; I: Integer; HW,HH: LongInt;
Begin
 DocToPage(ACx,ACy,P,LX_,LY_);
 PageToScr(P,LX_,LY_,SX,SY);
 { piece tenue : apercu a la position du curseur }
 If HeldOn Then Begin
  HW:=Sc(Held.W);HH:=Sc(Held.H);
  If Held.Kind=AR_ART Then
   DrawPiece(Held.Lib,Held.SX1,Held.SY1,Held.SX2,Held.SY2,Held.FH<>0,Held.FV<>0,
     SX,SY,HW,HH);
  If Held.Kind=AR_BOX Then Begin
   SetColor(INK);Rectangle(SX,SY,SX+HW-1,SY+HH-1);
  End;
  If Held.Kind=AR_LINE Then Line(SX,SY,SX+HW-1,SY+HH-1);
  DotRect(SX-1,SY-1,SX+HW,SY+HH);
 End;
 SetWriteMode(XORPut);
 SetColor(PAPER);
 SetLineStyle(SolidLn,0,1);
 Line(Integer(SX)-9,Integer(SY),Integer(SX)+9,Integer(SY));
 Line(Integer(SX),Integer(SY)-9,Integer(SX),Integer(SY)+9);
 SetWriteMode(NormalPut);
 { trace en cours }
 If DrawStep=1 Then Begin
  DocToPage(DrawX0,DrawY0,P,LX_,LY_);
  PageToScr(P,LX_,LY_,SX,SY);
  DotRect(Integer(SX),Integer(SY),Integer(SX)+4,Integer(SY)+4);
 End;
End;

Procedure DrawViewArea;
Var P: Integer; Ok: Boolean;
Begin
 CalcOrg;
 SetViewPort(0,MENU_H+1,SCR_W-1,PANEL_Y-1,True);
 PatBar(0,0,VW-1,VH-1,PatStripe);
 For P:=1 To NPg Do
  If (PgY0(P)<=VH+4) And (PgY0(P)+Sc(PGH)>=-4) Then
   DrawPageFull(P,OrgX,PgY0(P),GuidesOn);
 If Mode=MD_ART Then DrawArtCursor;
 CaretOn:=False;
 CaretGeom(Ok);
 If Ok Then ToggleCaret;
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
End;

{ Fait defiler la fenetre pour voir la ligne I }
Procedure ScrollToLine(I: Integer);
Var Top,Bot,XS: LongInt;
Begin
 If I<0 Then Exit;
 Top:=6+LongInt(Lines^[I].Pg-1)*StrideP+Sc(Lines^[I].Y);
 Bot:=Top+Sc(Lines^[I].H);
 If Top<ScrY+4 Then ScrY:=Top-4
 Else If Bot>ScrY+VH-4 Then ScrY:=Bot-VH+4;
 If Not Greek Then Begin
  XS:=6+Sc(XOfPos(I,Cur));
  If XS<ScrX+20 Then ScrX:=XS-60
  Else If XS>ScrX+VW-20 Then ScrX:=XS-VW+60;
 End;
 ClampScroll;
End;

Procedure ScrollToDoc(DX,DY: LongInt);
Var P: Integer; LX_,LY_,SX,SY: LongInt;
Begin
 DocToPage(DX,DY,P,LX_,LY_);
 SX:=6+Sc(LX_);
 SY:=6+LongInt(P-1)*StrideP+Sc(LY_);
 If SY<ScrY+20 Then ScrY:=SY-40
 Else If SY>ScrY+VH-40 Then ScrY:=SY-VH+60;
 If SX<ScrX+20 Then ScrX:=SX-60
 Else If SX>ScrX+VW-40 Then ScrX:=SX-VW+80;
 ClampScroll;
End;

{ ====================================================================== }
{                  DIALOGUES (style GEM, repris de Papyrus)              }
{ ====================================================================== }

Procedure DrawAll; Forward;

Function ListCount(L: Integer): Integer;
Begin
 Case L Of
  1: ListCount:=4;
  2: ListCount:=5;
  3: ListCount:=3;
  4: ListCount:=2;
  5: ListCount:=2;
  Else ListCount:=0;
 End;
End;

Function ListItemFr(L,I: Integer): String;
Begin
 ListItemFr:='';
 Case L Of
  1: Case I Of
      1: ListItemFr:='Gauche';
      2: ListItemFr:='Droite';
      3: ListItemFr:='Centr'#130;
      4: ListItemFr:='Justifi'#130;
     End;
  2: Case I Of
      1: ListItemFr:='Texte par-dessus';
      2: ListItemFr:='Texte des deux c'#147't'#130's';
      3: ListItemFr:='Texte '#133' gauche seul';
      4: ListItemFr:='Texte '#133' droite seul';
      5: ListItemFr:='Zone d'#130'gag'#130'e';
     End;
  3: Case I Of
      1: ListItemFr:='Grand pas (16)';
      2: ListItemFr:='Pas moyen (4)';
      3: ListItemFr:='Un point (1)';
     End;
  4: Case I Of
      1: ListItemFr:='Ligne';
      2: ListItemFr:='Bo'#140'te';
     End;
  5: Case I Of
      1: ListItemFr:='Horizontalement';
      2: ListItemFr:='Verticalement';
     End;
 End;
End;

Function ListItem(L,I: Integer): String;
Begin
 ListItem:=Tr(ListItemFr(L,I));
End;

Function ListMain(I: Integer): String;
Begin
 Case I Of
  1: ListMain:='Commencer un nouveau journal';
  2: ListMain:='Continuer le journal courant';
  3: ListMain:='Choisir un journal enregistr'#130;
  4: ListMain:='Quitter NewsMaster';
 Else ListMain:='';
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
       If InBox(E.X,E.Y,X,Y+2,X+W,Y+H-2) Then I:=Integer((E.Y-Y-2) Div 16+1)
         Else I:=0;
       If I>N Then I:=N;
       If I<>Hi Then Begin Hi:=I;Redraw:=True;End;
      End;
   2: Begin
       If InBox(E.X,E.Y,X,Y+2,X+W,Y+H-2) Then Res:=Integer((E.Y-Y-2) Div 16+1);
       If Res>N Then Res:=N;
       Done:=True;
      End;
   3: If Armed And InBox(E.X,E.Y,X,Y+2,X+W,Y+H-2) And (Hi>0) Then Begin Res:=Hi;
     Done:=True;End;
   1: Case E.Key Of
       K_ESC: Done:=True;
       K_UP: Begin If Hi>1 Then Dec(Hi) Else Hi:=N;Redraw:=True;End;
       K_DOWN: Begin If (Hi<N) And (Hi>0) Then Inc(Hi) Else Hi:=1;Redraw:=True;
         End;
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

Procedure CLabel(X,Y: Integer; Const T0: String);
Var I: Integer; T: String;
Begin
 T:=Tr(T0);
 I:=AddCtl(C_LABEL,0,X,Y,TextW(T),10,T);
End;

Procedure CEdit(Id,X,Y,W: Integer; Const Init,Sfx: String; Numeric: Boolean);
Var I: Integer;
Begin
 I:=AddCtl(C_EDIT,Id,X,Y,W,16,'');
 DC[I].Str:=Init;DC[I].Sfx:=Sfx;DC[I].Num:=Numeric;
 If DlgFocus=0 Then DlgFocus:=I;
End;

Procedure CCheck(Id,X,Y: Integer; Const T0: String; On: Boolean);
Var I: Integer; T: String;
Begin
 T:=Tr(T0);
 I:=AddCtl(C_CHECK,Id,X,Y,TextW(T)+20,14,T);
 DC[I].Val:=Ord(On);
End;

Procedure CRadio(Id,Grp,Val,X,Y: Integer; Const T0: String; Sel: Boolean);
Var I: Integer; T: String;
Begin
 T:=Tr(T0);
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

Function CtlIdx(Id: Integer): Integer;
Var I: Integer;
Begin
 CtlIdx:=0;
 For I:=1 To NDC Do If (DC[I].Id=Id) And (DC[I].Kind<>C_BTN) Then Begin
   CtlIdx:=I;Exit;End;
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

Function CRad(G: Integer): Integer;
Var I: Integer;
Begin
 CRad:=0;
 For I:=1 To NDC Do
  If (DC[I].Kind=C_RADIO) And (DC[I].Grp=G) And DC[I].On Then CRad:=DC[I].Val;
End;

Procedure DlgFrame(X,Y,W,H: Integer; Const Title0: String);
Var Title: String;
Begin
 Title:=Tr(Title0);
 Box(X+4,Y+4,X+W+4,Y+H+4,INK);
 Box(X,Y,X+W,Y+H,PAPER);
 Frame(X,Y,X+W,Y+H);
 Frame(X+1,Y+1,X+W-1,Y+H-1);
 Frame(X+2,Y+2,X+W-2,Y+H-2);
 PatBar(X+3,Y+3,X+W-3,Y+TBH,PatStripe);
 SetColor(INK);
 Line(X+3,Y+TBH+1,X+W-3,Y+TBH+1);
 Box(X+3,Y+3,X+22,Y+TBH,PAPER);
 Frame(X+3,Y+3,X+22,Y+TBH);
 Frame(X+8,Y+8,X+17,Y+TBH-5);
 Box((X+W-TextW(Title)) Div 2-6,Y+5,(X+W+TextW(Title)) Div 2+6,Y+TBH-2,PAPER);
 BText((X+W-TextW(Title)) Div 2,Y+9,Title);
End;

Procedure DlgDraw;
Var I,X,Y,W,H,Cx,Cy: Integer; S: String;
Begin
 HideMouse;
 DlgFrame(DlgX,DlgY,DlgW,DlgH,DlgTitle);
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
   If InBox(E.X,E.Y,DlgX+3,DlgY+3,DlgX+22,DlgY+TBH) Then Begin Res:=2;
     Done:=True;End
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
        Res:=DC[I].Id;Done:=True;
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

Procedure MsgBox(Const Title0,Txt0: String);
Var Lns: Array[1..12] Of String[60]; N,I,W,P: Integer; S,Title,Txt: String;
Begin
 Title:=Tr(Title0);Txt:=Tr(Txt0);
 N:=0;S:=Txt;W:=TextW(Title)+80;
 While (S<>'') And (N<12) Do Begin
  P:=Pos('|',S);
  Inc(N);
  If P=0 Then Begin Lns[N]:=Copy(S,1,60);S:='';End
  Else Begin Lns[N]:=Copy(S,1,P-1);Delete(S,1,P);End;
  If TextW(Lns[N])+40>W Then W:=TextW(Lns[N])+40;
 End;
 If W<240 Then W:=240;
 DlgInit(99,W,N*12+TBH+60,Title);
 For I:=1 To N Do CLabel(20,TBH+14+(I-1)*12,Lns[I]);
 CButton(1,(W-70) Div 2,N*12+TBH+26,70,20,'OK',True,True);
 RunDialog;
End;

Function ConfirmBox(Const Txt0: String): Boolean;
Var W: Integer; Txt: String;
Begin
 Txt:=Tr(Txt0);
 W:=TextW(Txt)+40;
 If W<260 Then W:=260;
 DlgInit(98,W,TBH+80,'NewsMaster');
 CLabel(20,TBH+16,Txt);
 CButton(1,20,TBH+44,80,20,'&Oui',True,True);
 CButton(2,W-100,TBH+44,80,20,'&Non',False,True);
 ConfirmBox:=RunDialog=1;
End;

Function InputBox(Const Title0,Prompt0: String; Var S: String; MaxLen: Integer):
  Boolean;
Var W: Integer; Title,Prompt: String;
Begin
 Title:=Tr(Title0);Prompt:=Tr(Prompt0);
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
 MTitle : Array[1..NMENU] Of String[8] = ('News','Fichier','Edition','Texte',
   'Image','Page','Vue','Options');

Procedure DoMenu(M,I: Integer); Forward;

Function MCount(M: Integer): Integer;
Begin
 Case M Of
  1: MCount:=4;
  2: MCount:=13;
  3: MCount:=10;
  4: MCount:=11;
  5: MCount:=24;
  6: MCount:=13;
  7: MCount:=8;
  8: MCount:=3;
  Else MCount:=0;
 End;
End;

{ '-' = separateur ; '|' separe le raccourci }
Function MLabelFr(M,I: Integer): String;
Begin
 MLabelFr:='';
 Case M Of
  1: Case I Of
      1: MLabelFr:=#192' propos de NewsMaster...';
      2: MLabelFr:='-';
      3: MLabelFr:='Statistiques...';
      4: MLabelFr:='M'#130'moire libre';
     End;
  2: Case I Of
      1: MLabelFr:='Menu principal...';
      2: MLabelFr:='Nouveau|^N';
      3: MLabelFr:='Ouvrir...|^O';
      4: MLabelFr:='Enregistrer|^S';
      5: MLabelFr:='Enregistrer sous...';
      6: MLabelFr:='-';
      7: MLabelFr:='Importer texte ASCII...';
      8: MLabelFr:='Exporter texte ASCII...';
      9: MLabelFr:='-';
      10: MLabelFr:='Imprimer la page (PBM)...';
      11: MLabelFr:='Imprimer tout (PBM)...';
      12: MLabelFr:='-';
      13: MLabelFr:='Quitter|^Q';
     End;
  3: Case I Of
      1: MLabelFr:='Annuler|^Z';
      2: MLabelFr:='-';
      3: MLabelFr:='Couper|^X';
      4: MLabelFr:='Copier|^C';
      5: MLabelFr:='Coller|^V';
      6: MLabelFr:='Effacer|Suppr';
      7: MLabelFr:='Tout s'#130'lectionner|^A';
      8: MLabelFr:='-';
      9: MLabelFr:='Chercher...|^F';
      10: MLabelFr:='Chercher suivant|^G';
     End;
  4: Case I Of
      1: MLabelFr:='Choisir la police...|^T';
      2: MLabelFr:='Police pr'#130'c'#130'dente';
      3: MLabelFr:='Police suivante';
      4: MLabelFr:='-';
      5: MLabelFr:='Aligner '#133' gauche|^L';
      6: MLabelFr:='Aligner '#133' droite|^R';
      7: MLabelFr:='Centrer|^E';
      8: MLabelFr:='Justifier|^J';
      9: MLabelFr:='-';
      10: MLabelFr:='Marquer la s'#130'lection';
      11: MLabelFr:='Mode '#130'dition du texte|F2';
     End;
  5: Case I Of
      1: MLabelFr:='Mode '#130'dition d''images|F3';
      2: MLabelFr:='-';
      3: MLabelFr:='Choisir une image...|F1';
      4: MLabelFr:='Prendre|F2';
      5: MLabelFr:='Prendre une copie|F3';
      6: MLabelFr:='Poser|Entr'#130'e';
      7: MLabelFr:='Supprimer|Suppr';
      8: MLabelFr:='-';
      9: MLabelFr:='Texte par-dessus';
      10: MLabelFr:='Texte des deux c'#147't'#130's';
      11: MLabelFr:='Texte '#133' gauche seul';
      12: MLabelFr:='Texte '#133' droite seul';
      13: MLabelFr:='Zone d'#130'gag'#130'e';
      14: MLabelFr:='-';
      15: MLabelFr:='Agrandir|+';
      16: MLabelFr:='R'#130'duire|-';
      17: MLabelFr:='Taille d''origine';
      18: MLabelFr:='Retourner horizontal.';
      19: MLabelFr:='Retourner vertical.';
      20: MLabelFr:='-';
      21: MLabelFr:='Tracer une ligne';
      22: MLabelFr:='Tracer une bo'#140'te';
      23: MLabelFr:='Motif de remplissage...';
      24: MLabelFr:=#144'paisseur du trait...';
     End;
  6: Case I Of
      1: MLabelFr:='Mode mise en page|F4';
      2: MLabelFr:='-';
      3: MLabelFr:='Ajouter une colonne';
      4: MLabelFr:='Supprimer une colonne';
      5: MLabelFr:='Ajouter un titre';
      6: MLabelFr:='Supprimer le titre';
      7: MLabelFr:='-';
      8: MLabelFr:='Ajouter une page';
      9: MLabelFr:='Supprimer la page';
      10: MLabelFr:='-';
      11: MLabelFr:='Page pr'#130'c'#130'dente|PgHaut';
      12: MLabelFr:='Page suivante|PgBas';
      13: MLabelFr:=#133' la page...';
     End;
  7: Case I Of
      1: MLabelFr:='Zoom avant (x2)';
      2: MLabelFr:='Vue normale';
      3: MLabelFr:='Largeur de la page';
      4: MLabelFr:='Page enti'#138're';
      5: MLabelFr:='-';
      6: MLabelFr:='Pas du curseur : grand';
      7: MLabelFr:='Pas du curseur : moyen';
      8: MLabelFr:='Pas du curseur : point';
     End;
  8: Case I Of
      1: MLabelFr:='Polices de NEWS.FLB';
      2: MLabelFr:='Guides de colonnes';
      3: MLabelFr:='Afficher les infos...';
     End;
 End;
End;

Function MLabel(M,I: Integer): String;
Begin
 MLabel:=Tr(MLabelFr(M,I));
End;

Function MTitleS(M: Integer): String;
Begin
 MTitleS:=Tr(MTitle[M]);
End;

Function CurArtFlow: Integer;
Begin
 If SelArt>0 Then CurArtFlow:=Arts[SelArt].Flow Else CurArtFlow:=-1;
End;

Function MChecked(M,I: Integer): Boolean;
Begin
 MChecked:=False;
 If M=4 Then If I In [5..8] Then
  MChecked:=(St[ASt].A^[ParaEndPos(ASt,Cur)]=I-5);
 If M=5 Then If I In [9..13] Then MChecked:=(CurArtFlow=I-9);
 If M=7 Then Begin
  If I In [1..4] Then MChecked:=(ViewNo=I);
  If I=6 Then MChecked:=(ACStep=16);
  If I=7 Then MChecked:=(ACStep=4);
  If I=8 Then MChecked:=(ACStep=1);
 End;
 If M=8 Then Begin
  If I=1 Then MChecked:=UseFLB;
  If I=2 Then MChecked:=GuidesOn;
 End;
End;

Function MEnabled(M,I: Integer): Boolean;
Var A,B: Integer;
Begin
 MEnabled:=True;
 If M=3 Then Begin
  If I=1 Then MEnabled:=UndoOK;
  If I In [3,4,6] Then MEnabled:=SelRange(A,B);
  If I=5 Then MEnabled:=ClipN>0;
 End;
 If M=5 Then
  If I In [7,9..13,15..19] Then MEnabled:=SelArt>0;
 If M=8 Then If I=1 Then MEnabled:=FLBFound;
End;

Function MSep(M,I: Integer): Boolean;
Begin
 MSep:=(MLabel(M,I)='-');
End;

Function MenuX(M: Integer): Integer;
Var I,X: Integer;
Begin
 X:=12;
 For I:=1 To M-1 Do X:=X+Length(MTitleS(I))*8+20;
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
  If (X>=MenuX(M)-8) And (X<=MenuX(M)+Length(MTitleS(M))*8+7) Then TitleHit:=M;
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
   Box(MenuX(M)-8,0,MenuX(M)+Length(MTitleS(M))*8+7,MENU_H-2,INK);
   WText(MenuX(M),5,MTitleS(M));
  End Else BText(MenuX(M),5,MTitleS(M));
 End;
End;

Procedure DrawDropDown;
Var X1,Y1,X2,Y2,I,Y,P: Integer; S,Sc_,Lb: String; Hi: Boolean;
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
   If P>0 Then Begin Lb:=Copy(S,1,P-1);Sc_:=Copy(S,P+1,20);End Else Begin
     Lb:=S;Sc_:='';End;
   Hi:=(I=MenuHi) And MEnabled(MenuOpen,I);
   If Hi Then Box(X1+1,Y,X2-1,Y+15,INK);
   If MChecked(MenuOpen,I) Then Begin
    If Hi Then WText(X1+4,Y+4,#251) Else PText(X1+4,Y+4,#251);
   End;
   If Not MEnabled(MenuOpen,I) Then Begin
    GreyText(X1+24,Y+4,Lb);
    If Sc_<>'' Then GreyText(X2-8-Length(Sc_)*8,Y+4,Sc_);
   End Else If Hi Then Begin
    WText(X1+24,Y+4,Lb);
    If Sc_<>'' Then WText(X2-8-Length(Sc_)*8,Y+4,Sc_);
   End Else Begin
    PText(X1+24,Y+4,Lb);
    If Sc_<>'' Then PText(X2-8-Length(Sc_)*8,Y+4,Sc_);
   End;
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
       K_LEFT: Begin Dec(M);If M<1 Then M:=NMENU;Hi:=NextItem(M,0,1);
         Redraw:=True;End;
       K_RIGHT: Begin Inc(M);If M>NMENU Then M:=1;Hi:=NextItem(M,0,1);
         Redraw:=True;End;
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
{                  PANNEAU DES TOUCHES DE FONCTION                       }
{ ====================================================================== }

Procedure AddPB(Const Txt: String; Ico: Byte);
Var P: Integer; S: String;
Begin
 If NPB>=10 Then Exit;
 Inc(NPB);
 PB[NPB].Fk:=NPB;PB[NPB].Ico:=Ico;PB[NPB].On:=True;
 PB[NPB].L1:='';PB[NPB].L2:='';PB[NPB].L3:='';
 S:=Tr(Txt);
 P:=Pos('|',S);
 If P=0 Then PB[NPB].L1:=Copy(S,1,7)
 Else Begin
  PB[NPB].L1:=Copy(S,1,Min2(P-1,7));Delete(S,1,P);
  P:=Pos('|',S);
  If P=0 Then PB[NPB].L2:=Copy(S,1,7)
  Else Begin PB[NPB].L2:=Copy(S,1,Min2(P-1,7));PB[NPB].L3:=Copy(S,P+1,7);End;
 End;
End;

Procedure SetPanel(M: Integer);
Begin
 Mode:=M;NPB:=0;PBDown:=0;
 Case M Of
  MD_MAIN: Begin
    PanelTitle:='MENU D'''#144'DITION PRINCIPAL';
    AddPB('VUE',1);AddPB('TEXTE',2);AddPB('IMAGES',3);
    AddPB('PAGE',4);AddPB('FICHIER',5);AddPB('IMPRIM.',6);
   End;
  MD_VIEW: Begin
    PanelTitle:='CHANGER LA VUE DU JOURNAL';
    AddPB('ZOOM|AVANT',0);AddPB('VUE|NORMALE',0);AddPB('LARGEUR|DE PAGE',0);
    AddPB('PAGE|ENTI'#138'RE',0);AddPB('PAGE|PR'#144'C.',0);AddPB('PAGE|SUIV.',
      0);
   End;
  MD_TEXT: Begin
    PanelTitle:='MODIFIER LE TEXTE';
    AddPB('CHOISIR|POLICE',0);AddPB('ALIGNE-|MENT',0);AddPB('S'#144'LEC-|TION',
      0);
    AddPB('COUPER',0);AddPB('COPIER',0);AddPB('COLLER',0);
    AddPB('IMPORT|ASCII',0);AddPB('ANNULER',0);
   End;
  MD_ART: Begin
    PanelTitle:='MODIFIER LES IMAGES';
    AddPB('CHOISIR|IMAGE',0);AddPB('PRENDRE',0);AddPB('PRENDRE|COPIE',0);
    AddPB('POSER',0);AddPB('TAILLE',0);AddPB('ROGNER',0);AddPB('HABIL-|LAGE',0);
    AddPB('RETOUR-|NER',0);AddPB('LIGNE|BO'#139'TE',0);AddPB('SUPPR.',0);
   End;
  MD_LAYOUT: Begin
    PanelTitle:='MODIFIER LA MISE EN PAGE';
    AddPB('AJOUT|COLONNE',0);AddPB('SUPPR.|COLONNE',0);AddPB('AJOUT|TITRE',0);
    AddPB('SUPPR.|TITRE',0);AddPB('AJOUT|PAGE',0);AddPB('SUPPR.|PAGE',0);
   End;
  MD_FILE: Begin
    PanelTitle:='CHARGER ET ENREGISTRER';
    AddPB('NOUVEAU',0);AddPB('OUVRIR',0);AddPB('ENREG.',0);
    AddPB('ENREG.|SOUS',0);AddPB('MENU|PRINC.',0);AddPB('QUITTER',0);
   End;
  MD_PRINT: Begin
    PanelTitle:='IMPRIMER LE JOURNAL';
    AddPB('CETTE|PAGE',0);AddPB('TOUTES|PAGES',0);AddPB('EXPORT|TEXTE',0);
   End;
 End;
 NeedDraw:=True;
End;

{ Icones des boutons du menu principal (zone 32 x 30) }
Procedure DrawIcon(N,X,Y: Integer);
Var C: Integer;
Begin
 SetColor(INK);SetLineStyle(SolidLn,0,1);SetFill(INK);
 Case N Of
  1: Begin
    Circle(X+13,Y+12,10);Circle(X+13,Y+12,9);
    Line(X+21,Y+20,X+30,Y+29);Line(X+22,Y+19,X+31,Y+28);Line(X+20,Y+21,X+29,
      Y+30);
    Line(X+8,Y+9,X+18,Y+9);Line(X+7,Y+12,X+19,Y+12);Line(X+8,Y+15,X+16,Y+15);
   End;
  2: Begin
    Bar(X+5,Y+4,X+8,Y+26);Bar(X+5,Y+4,X+19,Y+7);
    Bar(X+5,Y+13,X+16,Y+16);Bar(X+5,Y+23,X+19,Y+26);
    Line(X+25,Y+4,X+25,Y+26);Line(X+22,Y+4,X+28,Y+4);Line(X+22,Y+26,X+28,Y+26);
   End;
  3: Begin
    Rectangle(X+2,Y+2,X+29,Y+27);Rectangle(X+4,Y+4,X+27,Y+25);
    Circle(X+11,Y+11,3);
    Line(X+4,Y+25,X+13,Y+14);Line(X+13,Y+14,X+19,Y+21);
    Line(X+19,Y+21,X+22,Y+17);Line(X+22,Y+17,X+27,Y+25);
   End;
  4: Begin
    Rectangle(X+5,Y+1,X+27,Y+28);
    Bar(X+8,Y+4,X+24,Y+8);
    For C:=0 To 2 Do PatBar(X+8+C*6,Y+11,X+11+C*6,Y+25,PatGrey);
    For C:=0 To 2 Do Rectangle(X+8+C*6,Y+11,X+11+C*6,Y+25);
   End;
  5: Begin
    Rectangle(X+3,Y+2,X+29,Y+28);
    Bar(X+10,Y+2,X+22,Y+10);
    SetColor(PAPER);Bar(X+17,Y+4,X+20,Y+8);SetColor(INK);
    Rectangle(X+7,Y+15,X+25,Y+27);
    Line(X+9,Y+19,X+23,Y+19);Line(X+9,Y+23,X+23,Y+23);
   End;
  6: Begin
    Rectangle(X+9,Y+1,X+23,Y+10);
    Line(X+11,Y+4,X+21,Y+4);Line(X+11,Y+7,X+21,Y+7);
    Bar(X+3,Y+10,X+29,Y+20);
    Rectangle(X+9,Y+17,X+23,Y+28);
    SetColor(PAPER);Line(X+11,Y+21,X+21,Y+21);Line(X+11,Y+24,X+21,Y+24);
      SetColor(INK);
    SetColor(PAPER);Line(X+5,Y+13,X+8,Y+13);SetColor(INK);
   End;
 End;
End;

Procedure DrawPanelButton(I: Integer);
Var X,Y,W,H,TX: Integer; S: String;
Begin
 X:=8+(I-1)*62;Y:=PANEL_Y+34;W:=58;H:=58;
 Box(X+3,Y+3,X+W+3,Y+H+3,INK);
 Box(X,Y,X+W,Y+H,PAPER);
 Frame(X,Y,X+W,Y+H);
 S:='F'+IntStr(I);
 BText(X+(W-TextW(S)) Div 2,Y+3,S);
 SetColor(INK);Line(X,Y+13,X+W,Y+13);
 If PB[I].Ico>0 Then Begin
  DrawIcon(PB[I].Ico,X+13,Y+19);
 End Else Begin
  If PB[I].L2='' Then Begin
   PText(X+(W-TextW(PB[I].L1)) Div 2,Y+30,PB[I].L1);
  End Else If PB[I].L3='' Then Begin
   PText(X+(W-TextW(PB[I].L1)) Div 2,Y+24,PB[I].L1);
   PText(X+(W-TextW(PB[I].L2)) Div 2,Y+37,PB[I].L2);
  End Else Begin
   PText(X+(W-TextW(PB[I].L1)) Div 2,Y+19,PB[I].L1);
   PText(X+(W-TextW(PB[I].L2)) Div 2,Y+31,PB[I].L2);
   PText(X+(W-TextW(PB[I].L3)) Div 2,Y+43,PB[I].L3);
  End;
 End;
 If PBDown=I Then Begin
  SetWriteMode(XORPut);SetColor(PAPER);
  For TX:=Y+1 To Y+H-1 Do Line(X+1,TX,X+W-1,TX);
  SetWriteMode(NormalPut);
 End;
End;

Function PanelHit(X,Y: LongInt): Integer;
Var I: Integer;
Begin
 PanelHit:=0;
 For I:=1 To NPB Do
  If InBox(X,Y,8+(I-1)*62,PANEL_Y+34,8+(I-1)*62+58,PANEL_Y+92) Then PanelHit:=I;
End;

Function ViewName: String;
Begin
 Case ViewNo Of
  1: ViewName:=Tr('ZOOM X2');
  2: ViewName:=Tr('NORMALE');
  3: ViewName:=Tr('LARGEUR');
  4: ViewName:=Tr('PAGE ENTI'#138'RE');
 Else ViewName:='';
 End;
End;

Function IndicatorText: String;
Var S: String;
Begin
 Case Mode Of
  MD_MAIN,MD_TEXT: Begin
    S:=Upper(FName[CurFont]);
    IndicatorText:=S;
   End;
  MD_VIEW: IndicatorText:=ViewName;
  MD_ART: Begin
    S:=Tr('PAS ')+IntStr(ACStep);
    If ArtSub=1 Then S:=Tr('TAILLE');
    If ArtSub=2 Then S:=Tr('ROGNAGE');
    If ArtSub=3 Then S:=Tr('TRAC'#144);
    IndicatorText:=S;
   End;
  MD_FILE,MD_PRINT: Begin
    If DocName='' Then IndicatorText:=Tr('SANS NOM') Else
      IndicatorText:=Upper(ShortName(DocName));
   End;
 Else IndicatorText:='';
 End;
End;

Procedure DrawPanel;
Var I,W,X: Integer; S: String;
Begin
 PatBar(0,PANEL_Y,SCR_W-1,SCR_H-1,PatStripe);
 SetColor(INK);SetLineStyle(SolidLn,0,1);
 Line(0,PANEL_Y,SCR_W-1,PANEL_Y);
 Line(0,PANEL_Y+1,SCR_W-1,PANEL_Y+1);
 S:=Tr(PanelTitle);
 W:=TextW(S)+24;
 LabelBox((SCR_W-W) Div 2,PANEL_Y+8,(SCR_W+W) Div 2,PANEL_Y+26,S);
 { page courante }
 S:=Tr('PAGE ')+IntStr(CurPage)+'/'+IntStr(NPg);
 If (Mode=MD_TEXT) And (Mode<>MD_LAYOUT) Then Begin
  I:=LineOfPos(ASt,Cur);
  If I>=0 Then S:=Tr('PAGE ')+IntStr(Lines^[I].Pg)+'/'+IntStr(NPg);
 End;
 LabelBox(14,PANEL_Y+8,14+TextW(S)+20,PANEL_Y+26,S);
 { message d'etat }
 If (StatusMsg<>'') And (Tick>=StatusT) And (Tick-StatusT<500) Then Begin
  W:=TextW(StatusMsg)+20;
  LabelBox(SCR_W-14-W,PANEL_Y+8,SCR_W-14,PANEL_Y+26,StatusMsg);
 End Else If Overflow And (Mode=MD_TEXT) Then Begin
  S:=Tr('TEXTE EN TROP');
  LabelBox(SCR_W-14-TextW(S)-20,PANEL_Y+8,SCR_W-14,PANEL_Y+26,S);
 End;
 For I:=1 To NPB Do DrawPanelButton(I);
 S:=IndicatorText;
 If S<>'' Then Begin
  W:=TextW(S)+20;
  If W<80 Then W:=80;
  If NPB>8 Then Begin
   If Not ((StatusMsg<>'') And (Tick>=StatusT) And (Tick-StatusT<500)) And Not
     (Overflow And (Mode=MD_TEXT)) Then
    LabelBox(SCR_W-14-W,PANEL_Y+8,SCR_W-14,PANEL_Y+26,S);
  End Else
   LabelBox(SCR_W-14-W,PANEL_Y+64,SCR_W-14,PANEL_Y+82,S);
 End;
End;

{ ====================================================================== }
{               ECRAN DE MISE EN PAGE (apercu en miniature)              }
{ ====================================================================== }

Procedure DrawLayoutScreen;
Var X0,Y0,SvN,SvD,Yb: Integer; S: String; W,I: Integer;
Begin
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 PatBar(0,MENU_H,SCR_W-1,SCR_H-1,PatStripe);
 SvN:=ZN;SvD:=ZD;
 ZN:=3;ZD:=10;
 X0:=(SCR_W-Sc(PGW)) Div 2;Y0:=MENU_H+10;
 DrawPageFull(CurPage,X0,Y0,True);
 Yb:=Y0+Sc(PGH)+20;
 ZN:=SvN;ZD:=SvD;
 S:=Tr('MISE EN PAGE - PAGE ')+IntStr(CurPage)+'/'+IntStr(NPg)+' '+
   '- '+IntStr(NCol[CurPage]);
 If NCol[CurPage]>1 Then S:=S+Tr(' COLONNES') Else S:=S+Tr(' COLONNE');
 If HasHead[CurPage] Then S:=S+Tr(' + TITRE');
 W:=TextW(S)+30;
 LabelBox((SCR_W-W) Div 2,Yb,(SCR_W+W) Div 2,Yb+20,S);
 For I:=1 To NPB Do Begin
  DrawPanelButton(I);
 End;
End;

{ ====================================================================== }
{                           VUE ET DEFILEMENT                            }
{ ====================================================================== }

Procedure SetView(V: Integer);
Var I: Integer;
Begin
 ViewNo:=V;
 Case V Of
  1: Begin ZN:=2;ZD:=1;End;
  2: Begin ZN:=1;ZD:=1;End;
  3: Begin ZN:=4;ZD:=5;End;
  4: Begin ZN:=1;ZD:=3;End;
 End;
 If CurPage<1 Then CurPage:=1;
 If CurPage>NPg Then CurPage:=NPg;
 ScrX:=0;
 ScrY:=LongInt(CurPage-1)*StrideP;
 If (Mode=MD_TEXT) And Not Greek Then Begin
  I:=LineOfPos(ASt,Cur);
  If I>=0 Then ScrollToLine(I);
 End;
 ClampScroll;
 NeedDraw:=True;
End;

Procedure ScrollBy(DX,DY: LongInt);
Begin
 ScrX:=ScrX+DX;ScrY:=ScrY+DY;
 ClampScroll;
 NeedDraw:=True;
End;

Procedure GotoPage(P: Integer);
Begin
 If P<1 Then P:=1;
 If P>NPg Then P:=NPg;
 CurPage:=P;
 ScrY:=LongInt(P-1)*StrideP;
 ClampScroll;
 If Mode=MD_ART Then Begin
  ACy:=LongInt(P-1)*(PGH+PGGAP)+MRG;
 End;
 NeedDraw:=True;
End;

{ ====================================================================== }
{                          EDITION DU TEXTE                              }
{ ====================================================================== }

Procedure SyncFont;
Begin
 If (Cur>0) And (St[ASt].T^[Cur-1]<>13) Then CurFont:=St[ASt].F^[Cur-1]
 Else CurFont:=St[ASt].F^[Cur];
End;

Procedure AfterEdit;
Var I: Integer;
Begin
 Modified:=True;
 Relayout;
 I:=LineOfPos(ASt,Cur);
 If I>=0 Then Begin ScrollToLine(I);CurPage:=Lines^[I].Pg;End;
End;

Procedure Moved;
Var I: Integer;
Begin
 TypRun:=False;
 SyncFont;
 I:=LineOfPos(ASt,Cur);
 If I>=0 Then Begin ScrollToLine(I);CurPage:=Lines^[I].Pg;End;
 NeedDraw:=True;
End;

Function DelSel: Boolean;
Var A,B: Integer;
Begin
 DelSel:=False;
 If SelRange(A,B) Then Begin
  StDel(ASt,A,B);Cur:=A;SelA:=-1;MarkMode:=False;DelSel:=True;
 End Else SelA:=-1;
End;

Procedure TypeChar(Ch: Byte);
Var Al: Byte; A,B: Integer;
Begin
 If SelRange(A,B) Then Begin PushUndo;TypRun:=True;DelSel;End
 Else If Not TypRun Then Begin PushUndo;TypRun:=True;End;
 If Ch=13 Then Al:=St[ASt].A^[ParaEndPos(ASt,Cur)] Else Al:=0;
 If StIns(ASt,Cur,Ch,CurFont,Al) Then Inc(Cur)
 Else SetStatus('TEXTE TROP LONG');
 SelA:=-1;
 AfterEdit;
End;

Procedure DoBackspace;
Var A,B: Integer;
Begin
 If SelRange(A,B) Then Begin PushUndo;DelSel;AfterEdit;Exit;End;
 SelA:=-1;
 If Cur=0 Then Exit;
 If Not TypRun Then Begin PushUndo;TypRun:=True;End;
 StDel(ASt,Cur-1,Cur);Dec(Cur);
 AfterEdit;
End;

Procedure DoDelete;
Var A,B: Integer;
Begin
 If SelRange(A,B) Then Begin PushUndo;DelSel;AfterEdit;Exit;End;
 SelA:=-1;
 If Cur>=St[ASt].Len Then Exit;
 If Not TypRun Then Begin PushUndo;TypRun:=True;End;
 StDel(ASt,Cur,Cur+1);
 AfterEdit;
End;

Procedure MoveTo(P: Integer);
Begin
 If P<0 Then P:=0;
 If P>St[ASt].Len Then P:=St[ASt].Len;
 If MarkMode Then Begin
  If SelA<0 Then SelA:=Cur;
 End Else SelA:=-1;
 Cur:=P;WantX:=-1;
 Moved;
End;

Procedure CurUpDown(Dir: Integer);
Var I,J,P: Integer;
Begin
 I:=LineOfPos(ASt,Cur);
 If I<0 Then Exit;
 If WantX<0 Then WantX:=XOfPos(I,Cur)-Lines^[I].X;
 J:=I+Dir;
 While (J>=0) And (J<NLn) And (Lines^[J].Sty<>ASt) Do J:=J+Dir;
 If (J<0) Or (J>=NLn) Then Exit;
 P:=PosAtX(J,Lines^[J].X+WantX);
 If P>Lines^[J].E Then P:=Lines^[J].E;
 If MarkMode Then Begin
  If SelA<0 Then SelA:=Cur;
 End Else SelA:=-1;
 Cur:=P;
 TypRun:=False;SyncFont;
 ScrollToLine(J);CurPage:=Lines^[J].Pg;
 NeedDraw:=True;
End;

Procedure CurLineEdge(Home: Boolean);
Var I: Integer;
Begin
 I:=LineOfPos(ASt,Cur);
 If I<0 Then Exit;
 If Home Then MoveTo(Lines^[I].S) Else MoveTo(Lines^[I].E);
End;

Procedure ClipCopy;
Var A,B,N: Integer;
Begin
 If Not SelRange(A,B) Then Exit;
 N:=B-A;
 If N>CLIPCAP Then N:=CLIPCAP;
 Move(St[ASt].T^[A],ClipT^,N);
 Move(St[ASt].F^[A],ClipF^,N);
 ClipN:=N;
 SetStatus(IntStr(N)+Tr(' CARACT'#138'RES COPI'#144'S'));
End;

Procedure ClipCut;
Var A,B: Integer;
Begin
 If Not SelRange(A,B) Then Exit;
 ClipCopy;
 PushUndo;
 DelSel;
 AfterEdit;
End;

Procedure ClipPaste;
Var A,B,N: Integer; AA: Byte;
Begin
 If ClipN=0 Then Exit;
 PushUndo;
 If SelRange(A,B) Then DelSel;
 N:=ClipN;
 If St[ASt].Len+N>St[ASt].Cap Then N:=St[ASt].Cap-St[ASt].Len;
 If N<=0 Then Begin SetStatus('TEXTE TROP LONG');Exit;End;
 Move(St[ASt].T^[Cur],St[ASt].T^[Cur+N],St[ASt].Len-Cur+1);
 Move(St[ASt].F^[Cur],St[ASt].F^[Cur+N],St[ASt].Len-Cur+1);
 Move(St[ASt].A^[Cur],St[ASt].A^[Cur+N],St[ASt].Len-Cur+1);
 Move(ClipT^,St[ASt].T^[Cur],N);
 Move(ClipF^,St[ASt].F^[Cur],N);
 FillChar(St[ASt].A^[Cur],N,AL_LEFT);
 Inc(St[ASt].Len,N);
 Cur:=Cur+N;SelA:=-1;
 AfterEdit;
End;

Procedure SelectAll;
Begin
 SelA:=0;Cur:=St[ASt].Len;
 Moved;
End;

Procedure ToggleMark;
Begin
 MarkMode:=Not MarkMode;
 If MarkMode Then Begin SelA:=Cur;SetStatus('MARQUEZ AVEC LES FL'#138'CHES');End
 Else SetStatus('S'#144'LECTION FIX'#144'E');
 NeedDraw:=True;
End;

Procedure SetAlign(Al: Integer);
Var A,B,P,PE: Integer;
Begin
 PushUndo;
 If Not SelRange(A,B) Then Begin A:=Cur;B:=Cur;End;
 P:=ParaEndPos(ASt,A);
 PE:=ParaEndPos(ASt,B);
 While True Do Begin
  St[ASt].A^[P]:=Al;
  If (P>=PE) Or (P>=St[ASt].Len) Then Break;
  P:=ParaEndPos(ASt,P+1);
 End;
 Modified:=True;
 Relayout;
End;

Procedure SetFontSel(F: Integer);
Var A,B,I: Integer;
Begin
 If SelRange(A,B) Then Begin
  PushUndo;
  For I:=A To B-1 Do St[ASt].F^[I]:=F;
  CurFont:=F;
  Modified:=True;
  Relayout;
 End Else Begin
  CurFont:=F;
  St[ASt].F^[Cur]:=F;
  If (Cur<St[ASt].Len) And (St[ASt].T^[Cur]=13) Then St[ASt].F^[Cur]:=F;
  Relayout;
 End;
End;

{ ---- selecteur de police ---- }
Function PickFont(Cur0: Integer): Integer;
Var Sel,Top,I,Y,N,RowH,Rows,X0,Y0,W,H: Integer; E: TEvent; Done,Redraw: Boolean;
    S: String; LastT: LongInt;
Begin
 PickFont:=-1;
 Sel:=Cur0;Top:=0;Rows:=14;RowH:=14;
 W:=560;H:=Rows*RowH+TBH+56;
 X0:=(SCR_W-W) Div 2;Y0:=(SCR_H-H) Div 2-6;
 Done:=False;Redraw:=True;LastT:=0;
 Repeat
  If Sel<Top Then Top:=Sel;
  If Sel>=Top+Rows Then Top:=Sel-Rows+1;
  If Redraw Then Begin
   HideMouse;
   DlgFrame(X0,Y0,W,H,'Choisir une police');
   Box(X0+10,Y0+TBH+8,X0+240,Y0+TBH+8+Rows*RowH,PAPER);
   Frame(X0+10,Y0+TBH+8,X0+240,Y0+TBH+8+Rows*RowH);
   For I:=0 To Rows-1 Do
    If Top+I<NFont Then Begin
     Y:=Y0+TBH+10+I*RowH;
     If Top+I=Sel Then Begin
      Box(X0+11,Y-1,X0+239,Y+RowH-2,INK);
      WText(X0+16,Y+2,FName[Top+I]);
     End Else PText(X0+16,Y+2,FName[Top+I]);
    End;
   { apercu }
   Box(X0+250,Y0+TBH+8,X0+W-10,Y0+TBH+8+Rows*RowH,PAPER);
   Frame(X0+250,Y0+TBH+8,X0+W-10,Y0+TBH+8+Rows*RowH);
   SetViewPort(X0+251,Y0+TBH+9,X0+W-11,Y0+TBH+7+Rows*RowH,True);
   EnsureFont(Sel);
   N:=FAsc[Sel]+FDsc[Sel];
   Y:=4;
   S:='Journal NewsMaster';
   DrawStrF(Sel,6,Y,S);Y:=Y+N+4;
   If Y+N<Rows*RowH-4 Then Begin DrawStrF(Sel,6,Y,'ABCDEFGHIJKLMNOPQRSTU');
     Y:=Y+N+4;End;
   If Y+N<Rows*RowH-4 Then Begin DrawStrF(Sel,6,Y,'abcdefghijklmnopqrstu');
     Y:=Y+N+4;End;
   If Y+N<Rows*RowH-4 Then DrawStrF(Sel,6,Y,'0123456789 !?&%$.,;:()');
   SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
   Button(X0+W-190,Y0+H-34,X0+W-110,Y0+H-14,'OK',True,True);
   Button(X0+W-96,Y0+H-34,X0+W-16,Y0+H-14,'&Annuler',False,True);
   PText(X0+14,Y0+H-30,IntStr(NFont)+Tr(' polices'));
   If UseFLB Then PText(X0+14,Y0+H-20,'NEWS.FLB') Else PText(X0+14,Y0+H-20,
     Tr('int'#130'gr'#130'es'));
   ShowMouse;
   Redraw:=False;
  End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   Case E.Key Of
    K_ESC: Done:=True;
    K_ENTER: Begin PickFont:=Sel;Done:=True;End;
    K_UP: If Sel>0 Then Begin Dec(Sel);Redraw:=True;End;
    K_DOWN: If Sel<NFont-1 Then Begin Inc(Sel);Redraw:=True;End;
    K_PGUP: Begin Sel:=Sel-Rows;If Sel<0 Then Sel:=0;Redraw:=True;End;
    K_PGDN: Begin Sel:=Sel+Rows;If Sel>NFont-1 Then Sel:=NFont-1;Redraw:=True;
      End;
    K_HOME: Begin Sel:=0;Redraw:=True;End;
    K_END: Begin Sel:=NFont-1;Redraw:=True;End;
   End;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X0+10,Y0+TBH+10,X0+240,Y0+TBH+10+Rows*RowH) Then Begin
    I:=Top+Integer((E.Y-(Y0+TBH+10)) Div RowH);
    If (I>=0) And (I<NFont) Then Begin
     If (I=Sel) And (Tick-LastT<40) Then Begin PickFont:=Sel;Done:=True;End;
     Sel:=I;Redraw:=True;LastT:=Tick;
    End;
   End Else If InBox(E.X,E.Y,X0+W-190,Y0+H-34,X0+W-110,Y0+H-14) Then Begin
    PickFont:=Sel;Done:=True;
   End Else If InBox(E.X,E.Y,X0+W-96,Y0+H-34,X0+W-16,Y0+H-14) Then Done:=True
   Else If InBox(E.X,E.Y,X0+3,Y0+3,X0+22,Y0+TBH) Then Done:=True;
  End;
 Until Done;
 NeedDraw:=True;
End;

Procedure CmdFont;
Var F: Integer;
Begin
 F:=PickFont(CurFont);
 If F>=0 Then SetFontSel(F);
End;

Procedure CmdFontStep(Dir: Integer);
Var F: Integer;
Begin
 F:=CurFont+Dir;
 If F<0 Then F:=NFont-1;
 If F>=NFont Then F:=0;
 SetFontSel(F);
End;

Procedure CmdAlignPopup;
Var Cur0,R: Integer;
Begin
 Cur0:=St[ASt].A^[ParaEndPos(ASt,Cur)]+1;
 R:=PopupAt(8+1*62,PANEL_Y-80,110,1,Cur0);
 If R>0 Then SetAlign(R-1);
End;

Function MatchAt(Ps: Integer; Const Pat: String): Boolean;
Var I: Integer;
Begin
 MatchAt:=False;
 If Ps+Length(Pat)>St[ASt].Len Then Exit;
 For I:=1 To Length(Pat) Do
  If UpCase(Chr(St[ASt].T^[Ps+I-1]))<>UpCase(Pat[I]) Then Exit;
 MatchAt:=True;
End;

Procedure FindNextText;
Var I: Integer; Ok: Boolean;
Begin
 If FindStr='' Then Exit;
 Ok:=False;
 For I:=Cur+1 To St[ASt].Len-Length(FindStr) Do
  If MatchAt(I,FindStr) Then Begin
   SelA:=I;Cur:=I+Length(FindStr);Ok:=True;Break;
  End;
 If Not Ok Then
  For I:=0 To Cur Do
   If MatchAt(I,FindStr) Then Begin
    SelA:=I;Cur:=I+Length(FindStr);Ok:=True;Break;
   End;
 If Ok Then Begin MarkMode:=False;Moved;End
 Else SetStatus('INTROUVABLE');
End;

Procedure CmdFind;
Var S: String;
Begin
 S:=FindStr;
 If InputBox('Chercher','Texte '#133' chercher :',S,30) Then Begin
  FindStr:=Copy(S,1,40);
  If Mode<>MD_TEXT Then SetPanel(MD_TEXT);
  FindNextText;
 End;
End;

{ ====================================================================== }
{                       EDITION DES IMAGES                               }
{ ====================================================================== }

Procedure UpdateSelArt;
Var P: Integer; LX_,LY_: LongInt;
Begin
 DocToPage(ACx,ACy,P,LX_,LY_);
 CurPage:=P;
 SelArt:=ArtOnPage(P,Integer(LX_),Integer(LY_));
End;

Procedure DelArt(I: Integer);
Var K: Integer;
Begin
 If (I<1) Or (I>NArt) Then Exit;
 For K:=I To NArt-1 Do Arts[K]:=Arts[K+1];
 Dec(NArt);
 SelArt:=0;
 Modified:=True;
 Relayout;
 UpdateSelArt;
End;

Function AddArt(Const A: TArt): Integer;
Begin
 AddArt:=0;
 If NArt>=MAXART Then Begin SetStatus('TROP D''OBJETS');Exit;End;
 Inc(NArt);
 Arts[NArt]:=A;
 AddArt:=NArt;
End;

Procedure ClampArt(Var A: TArt);
Begin
 If A.W<4 Then A.W:=4;
 If A.H<4 Then A.H:=4;
 If A.W>PGW Then A.W:=PGW;
 If A.H>PGH Then A.H:=PGH;
 If A.X<0 Then A.X:=0;
 If A.Y<0 Then A.Y:=0;
 If A.X+A.W>PGW Then A.X:=PGW-A.W;
 If A.Y+A.H>PGH Then A.Y:=PGH-A.H;
End;

Procedure StampHeld;
Var P: Integer; LX_,LY_: LongInt; A: TArt; I: Integer;
Begin
 If Not HeldOn Then Begin SetStatus('RIEN A POSER');Exit;End;
 DocToPage(ACx,ACy,P,LX_,LY_);
 A:=Held;
 A.Pg:=P;A.X:=Integer(LX_);A.Y:=Integer(LY_);
 ClampArt(A);
 I:=AddArt(A);
 If I>0 Then Begin
  Modified:=True;
  Relayout;
  SelArt:=I;
 End;
End;

Procedure PickUp(Copy_: Boolean);
Begin
 If SelArt<=0 Then Begin SetStatus('AUCUNE IMAGE ICI');Exit;End;
 Held:=Arts[SelArt];
 HeldOn:=True;
 ACx:=Held.X;
 ACy:=LongInt(Held.Pg-1)*(PGH+PGGAP)+Held.Y;
 If Not Copy_ Then DelArt(SelArt);
 NeedDraw:=True;
End;

Function ArtPicker: Integer;
Var Sel,I,X0,Y0,W,H,Cols,CX,CY,YY: Integer; E: TEvent; Done,Redraw: Boolean;
Begin
 ArtPicker:=0;
 Sel:=LastPiece;If Sel<1 Then Sel:=1;
 Cols:=5;
 W:=Cols*96+24;H:=((NLib+Cols-1) Div Cols)*96+TBH+60;
 X0:=(SCR_W-W) Div 2;Y0:=(SCR_H-H) Div 2-6;
 Done:=False;Redraw:=True;
 Repeat
  If Redraw Then Begin
   HideMouse;
   DlgFrame(X0,Y0,W,H,'Choisir une image');
   For I:=1 To NLib Do Begin
    CX:=X0+12+((I-1) Mod Cols)*96;
    CY:=Y0+TBH+8+((I-1) Div Cols)*96;
    Box(CX,CY,CX+90,CY+90,PAPER);
    Frame(CX,CY,CX+90,CY+90);
    SetViewPort(CX+1,CY+1,CX+89,CY+89,True);
    DrawPiece(I,0,0,Lib[I].W,Lib[I].H,False,False,12,6,64,64);
    SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
    PText(CX+(90-TextW(Tr(Lib[I].Name))) Div 2,CY+78,Tr(Lib[I].Name));
    If I=Sel Then Begin
     SetWriteMode(XORPut);SetColor(PAPER);
     For YY:=CY+1 To CY+89 Do Line(CX+1,YY,CX+89,YY);
     SetWriteMode(NormalPut);
    End;
   End;
   Button(X0+W-190,Y0+H-34,X0+W-110,Y0+H-14,'OK',True,True);
   Button(X0+W-96,Y0+H-34,X0+W-16,Y0+H-14,'&Annuler',False,True);
   PText(X0+14,Y0+H-28,Tr('Fl'#138'ches : choisir  Entr'#130'e : valider'));
   ShowMouse;
   Redraw:=False;
  End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   Case E.Key Of
    K_ESC: Done:=True;
    K_ENTER: Begin ArtPicker:=Sel;Done:=True;End;
    K_LEFT: If Sel>1 Then Begin Dec(Sel);Redraw:=True;End;
    K_RIGHT: If Sel<NLib Then Begin Inc(Sel);Redraw:=True;End;
    K_UP: If Sel>Cols Then Begin Sel:=Sel-Cols;Redraw:=True;End;
    K_DOWN: If Sel+Cols<=NLib Then Begin Sel:=Sel+Cols;Redraw:=True;End;
   End;
  End Else If E.Kind=2 Then Begin
   For I:=1 To NLib Do Begin
    CX:=X0+12+((I-1) Mod Cols)*96;
    CY:=Y0+TBH+8+((I-1) Div Cols)*96;
    If InBox(E.X,E.Y,CX,CY,CX+90,CY+90) Then Begin
     If I=Sel Then Begin ArtPicker:=Sel;Done:=True;End
     Else Begin Sel:=I;Redraw:=True;End;
    End;
   End;
   If InBox(E.X,E.Y,X0+W-190,Y0+H-34,X0+W-110,Y0+H-14) Then Begin
     ArtPicker:=Sel;Done:=True;End;
   If InBox(E.X,E.Y,X0+W-96,Y0+H-34,X0+W-16,Y0+H-14) Then Done:=True;
   If InBox(E.X,E.Y,X0+3,Y0+3,X0+22,Y0+TBH) Then Done:=True;
  End;
 Until Done;
 NeedDraw:=True;
End;

Procedure CmdChooseArt;
Var L: Integer;
Begin
 L:=ArtPicker;
 If L<=0 Then Exit;
 LastPiece:=L;
 FillChar(Held,SizeOf(Held),0);
 Held.Kind:=AR_ART;Held.Lib:=L;Held.Flow:=FL_BOTH;
 Held.W:=Lib[L].W*3 Div 2;Held.H:=Lib[L].H*3 Div 2;
 Held.SX1:=0;Held.SY1:=0;Held.SX2:=Lib[L].W;Held.SY2:=Lib[L].H;
 HeldOn:=True;
 If Mode<>MD_ART Then SetPanel(MD_ART);
 ArtSub:=0;
 NeedDraw:=True;
End;

{ Objet cible des operations : l'objet tenu, sinon l'objet selectionne }
Function TargetOk: Boolean;
Begin
 TargetOk:=HeldOn Or (SelArt>0);
End;

Procedure ArtSetFlow(Fl: Integer);
Begin
 If HeldOn Then Held.Flow:=Fl
 Else If SelArt>0 Then Arts[SelArt].Flow:=Fl
 Else Exit;
 Modified:=True;
 Relayout;
End;

Procedure ArtFlip(Horiz: Boolean);
Begin
 If HeldOn Then Begin
  If Horiz Then Held.FH:=1-Held.FH Else Held.FV:=1-Held.FV;
 End Else If SelArt>0 Then Begin
  If Horiz Then Arts[SelArt].FH:=1-Arts[SelArt].FH Else
    Arts[SelArt].FV:=1-Arts[SelArt].FV;
 End Else Exit;
 Modified:=True;
 NeedDraw:=True;
End;

Procedure ArtResize(DW,DH: Integer);
Var A: TArt; NW,NH: Integer;
Begin
 If HeldOn Then A:=Held Else If SelArt>0 Then A:=Arts[SelArt] Else Exit;
 If A.Kind=AR_ART Then Begin
  NW:=A.W+DW;
  If DW=0 Then NW:=A.W-DH;
  If NW<8 Then NW:=8;
  If NW>PGW-2 Then NW:=PGW-2;
  NH:=Integer(LongInt(A.H)*NW Div A.W);
  If NH>PGH-2 Then Exit;
  A.W:=NW;A.H:=NH;
 End Else Begin
  A.W:=A.W+DW;A.H:=A.H+DH;
  If A.W<2 Then A.W:=2;
  If A.H<2 Then A.H:=2;
 End;
 ClampArt(A);
 If HeldOn Then Held:=A Else Arts[SelArt]:=A;
 Modified:=True;
 If Not HeldOn Then Relayout;
 NeedDraw:=True;
End;

Procedure ArtResetSize;
Var A: TArt;
Begin
 If HeldOn Then A:=Held Else If SelArt>0 Then A:=Arts[SelArt] Else Exit;
 If A.Kind=AR_ART Then Begin
  A.W:=(A.SX2-A.SX1)*3 Div 2;A.H:=(A.SY2-A.SY1)*3 Div 2;
 End;
 ClampArt(A);
 If HeldOn Then Held:=A Else Arts[SelArt]:=A;
 Modified:=True;
 If Not HeldOn Then Relayout;
 NeedDraw:=True;
End;

{ Rognage : D = pas en pixels source }
Procedure ArtCrop(DX,DY: Integer);
Var A: TArt; OW,OH,SW,SHh,NW,NH: Integer;
Begin
 If HeldOn Then A:=Held Else If SelArt>0 Then A:=Arts[SelArt] Else Exit;
 If A.Kind<>AR_ART Then Exit;
 SW:=A.SX2-A.SX1;SHh:=A.SY2-A.SY1;
 OW:=A.W;OH:=A.H;
 If CropEnd=0 Then Begin
  If (DX>0) And (SW-DX<4) Then DX:=0;
  If (A.SX1+DX<0) Then DX:=-A.SX1;
  If (DY>0) And (SHh-DY<4) Then DY:=0;
  If (A.SY1+DY<0) Then DY:=-A.SY1;
  A.SX1:=A.SX1+DX;A.SY1:=A.SY1+DY;
 End Else Begin
  If (DX<0) And (SW+DX<4) Then DX:=0;
  If A.SX2+DX>Lib[A.Lib].W Then DX:=Lib[A.Lib].W-A.SX2;
  If (DY<0) And (SHh+DY<4) Then DY:=0;
  If A.SY2+DY>Lib[A.Lib].H Then DY:=Lib[A.Lib].H-A.SY2;
  A.SX2:=A.SX2+DX;A.SY2:=A.SY2+DY;
 End;
 NW:=Integer(LongInt(OW)*(A.SX2-A.SX1) Div SW);
 NH:=Integer(LongInt(OH)*(A.SY2-A.SY1) Div SHh);
 If CropEnd=0 Then Begin
  A.X:=A.X+(OW-NW);A.Y:=A.Y+(OH-NH);
 End;
 A.W:=NW;A.H:=NH;
 If NW<2 Then A.W:=2;
 If NH<2 Then A.H:=2;
 If HeldOn Then Held:=A Else Arts[SelArt]:=A;
 Modified:=True;
 If Not HeldOn Then Relayout;
 NeedDraw:=True;
End;

Procedure ArtFinishDraw;
Var P1,P2: Integer; X1,Y1,X2,Y2: LongInt; A: TArt; I: Integer;
Begin
 DocToPage(DrawX0,DrawY0,P1,X1,Y1);
 DocToPage(ACx,ACy,P2,X2,Y2);
 DrawStep:=0;
 If P1<>P2 Then Begin SetStatus('M'#138'ME PAGE SVP');Exit;End;
 FillChar(A,SizeOf(A),0);
 A.Kind:=DrawKind;A.Pg:=P1;
 A.X:=Integer(Min2(X1,X2));A.Y:=Integer(Min2(Y1,Y2));
 A.W:=Integer(Abs(X2-X1));A.H:=Integer(Abs(Y2-Y1));
 If A.Kind=AR_LINE Then Begin
  If ((X2-X1)*(Y2-Y1))<0 Then A.FV:=1;
  If A.W<1 Then A.W:=1;
  If A.H<1 Then A.H:=1;
 End Else Begin
  If A.W<4 Then A.W:=4;
  If A.H<4 Then A.H:=4;
 End;
 A.Th:=DrawTh;A.Pat:=DrawPat;A.Flow:=FL_OVER;
 I:=AddArt(A);
 If I>0 Then Begin Modified:=True;Relayout;SelArt:=I;End;
End;

Procedure CmdDrawTool;
Var R: Integer;
Begin
 R:=PopupAt(8+8*62,PANEL_Y-50,100,4,DrawKind-1);
 If R>0 Then Begin
  DrawKind:=R+1;
  ArtSub:=3;DrawStep:=0;HeldOn:=False;
  SetStatus('ENTR'#144'E : POINT DE D'#144'PART');
 End;
End;

Procedure CmdPattern;
Var Sel,I,X0,Y0,W,H,CX,CY: Integer; E: TEvent; Done,Redraw: Boolean;
Begin
 Sel:=DrawPat;
 W:=6*50+24;H:=2*50+TBH+64;
 X0:=(SCR_W-W) Div 2;Y0:=(SCR_H-H) Div 2-6;
 Done:=False;Redraw:=True;
 Repeat
  If Redraw Then Begin
   HideMouse;
   DlgFrame(X0,Y0,W,H,'Motif de remplissage');
   For I:=0 To NPAT-1 Do Begin
    CX:=X0+12+(I Mod 6)*50;CY:=Y0+TBH+8+(I Div 6)*50;
    Box(CX,CY,CX+44,CY+44,PAPER);
    FillPat(I,CX+1,CY+1,CX+43,CY+43);
    If I=0 Then PText(CX+16,CY+18,'0');
    Frame(CX,CY,CX+44,CY+44);
    If I=Sel Then Begin Frame(CX-2,CY-2,CX+46,CY+46);Frame(CX-3,CY-3,CX+47,
      CY+47);End;
   End;
   Button(X0+W-190,Y0+H-34,X0+W-110,Y0+H-14,'OK',True,True);
   Button(X0+W-96,Y0+H-34,X0+W-16,Y0+H-14,'&Annuler',False,True);
   ShowMouse;
   Redraw:=False;
  End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   Case E.Key Of
    K_ESC: Done:=True;
    K_ENTER: Begin DrawPat:=Sel;Done:=True;End;
    K_LEFT: If Sel>0 Then Begin Dec(Sel);Redraw:=True;End;
    K_RIGHT: If Sel<NPAT-1 Then Begin Inc(Sel);Redraw:=True;End;
    K_UP: If Sel>=6 Then Begin Sel:=Sel-6;Redraw:=True;End;
    K_DOWN: If Sel+6<NPAT Then Begin Sel:=Sel+6;Redraw:=True;End;
   End;
  End Else If E.Kind=2 Then Begin
   For I:=0 To NPAT-1 Do Begin
    CX:=X0+12+(I Mod 6)*50;CY:=Y0+TBH+8+(I Div 6)*50;
    If InBox(E.X,E.Y,CX,CY,CX+44,CY+44) Then Begin
     If I=Sel Then Begin DrawPat:=Sel;Done:=True;End Else Begin Sel:=I;
       Redraw:=True;End;
    End;
   End;
   If InBox(E.X,E.Y,X0+W-190,Y0+H-34,X0+W-110,Y0+H-14) Then Begin DrawPat:=Sel;
     Done:=True;End;
   If InBox(E.X,E.Y,X0+W-96,Y0+H-34,X0+W-16,Y0+H-14) Then Done:=True;
  End;
 Until Done;
 If (SelArt>0) And (Arts[SelArt].Kind=AR_BOX) Then Arts[SelArt].Pat:=DrawPat;
 NeedDraw:=True;
End;

Procedure CmdThickness;
Var S: String; V: LongInt;
Begin
 S:=IntStr(DrawTh);
 If InputBox(#144'paisseur','Epaisseur du trait (1-12) :',S,3) Then Begin
  V:=ValInt(S,DrawTh);
  If V<1 Then V:=1;
  If V>12 Then V:=12;
  DrawTh:=V;
  If (SelArt>0) And (Arts[SelArt].Kind<>AR_ART) Then Begin
   Arts[SelArt].Th:=V;Modified:=True;
  End;
  NeedDraw:=True;
 End;
End;

{ Deplacement du curseur d'images }
Procedure ArtCursorMove(DX,DY: Integer);
Var MaxY: LongInt;
Begin
 ACx:=ACx+DX*ACStep;ACy:=ACy+DY*ACStep;
 If ACx<0 Then ACx:=0;
 If ACx>PGW-1 Then ACx:=PGW-1;
 If ACy<0 Then ACy:=0;
 MaxY:=LongInt(NPg)*(PGH+PGGAP)-PGGAP-1;
 If ACy>MaxY Then ACy:=MaxY;
 UpdateSelArt;
 ScrollToDoc(ACx,ACy);
 NeedDraw:=True;
End;

{ ====================================================================== }
{                       EDITION DE LA MISE EN PAGE                       }
{ ====================================================================== }

Procedure CmdAddCol;
Begin
 If NCol[CurPage]>=MAXCOL Then Begin
   SetStatus(Tr('MAXIMUM : ')+IntStr(MAXCOL)+Tr(' COLONNES'));Exit;End;
 Inc(NCol[CurPage]);Modified:=True;Relayout;
End;

Procedure CmdDelCol;
Begin
 If NCol[CurPage]<=1 Then Begin SetStatus('UNE COLONNE MINIMUM');Exit;End;
 Dec(NCol[CurPage]);Modified:=True;Relayout;
End;

Procedure CmdAddHead;
Begin
 If HasHead[CurPage] Then Begin SetStatus('TITRE D'#144'J'#133' PR'#144'SENT');
   Exit;End;
 HasHead[CurPage]:=True;
 If St[CurPage].Len=0 Then StAppend(CurPage,Tr('Titre'),DefHead);
 St[CurPage].A^[St[CurPage].Len]:=AL_CENTER;
 Modified:=True;Relayout;
End;

Procedure CmdDelHead;
Begin
 If Not HasHead[CurPage] Then Exit;
 HasHead[CurPage]:=False;
 If ASt=CurPage Then Begin ASt:=0;Cur:=0;SelA:=-1;End;
 Modified:=True;Relayout;
End;

Procedure CmdAddPage;
Begin
 If NPg>=MAXPG Then Begin
   SetStatus(Tr('MAXIMUM : ')+IntStr(MAXPG)+Tr(' PAGES'));Exit;End;
 Inc(NPg);
 NCol[NPg]:=NCol[CurPage];HasHead[NPg]:=False;
 StClear(NPg,DefHead,AL_CENTER);
 CurPage:=NPg;
 Modified:=True;Relayout;
End;

Procedure CmdDelPage;
Var I,K: Integer; Sv: TStory;
Begin
 If NPg<=1 Then Begin SetStatus('IMPOSSIBLE : UNE PAGE');Exit;End;
 I:=NArt;
 While I>=1 Do Begin
  If Arts[I].Pg=CurPage Then Begin
   For K:=I To NArt-1 Do Arts[K]:=Arts[K+1];
   Dec(NArt);
  End Else If Arts[I].Pg>CurPage Then Dec(Arts[I].Pg);
  Dec(I);
 End;
 Sv:=St[CurPage];
 For K:=CurPage To NPg-1 Do Begin
  St[K]:=St[K+1];NCol[K]:=NCol[K+1];HasHead[K]:=HasHead[K+1];
 End;
 St[NPg]:=Sv;
 StClear(NPg,DefHead,AL_CENTER);
 Dec(NPg);
 If ASt>NPg Then ASt:=0;
 If CurPage>NPg Then CurPage:=NPg;
 SelArt:=0;
 Modified:=True;Relayout;
End;

{ ====================================================================== }
{                         FICHIERS (.NWC)                                }
{ ====================================================================== }

Var
 OutF   : File;
 FileOk : Boolean;

Procedure WB(V: Integer);
Var B: Byte;
Begin
 B:=V And 255;
 {$I-}BlockWrite(OutF,B,1);{$I+}
 If IOResult<>0 Then FileOk:=False;
End;

Procedure WW(V: Integer);
Begin
 WB(V And 255);WB((V Shr 8) And 255);
End;

Function RB: Integer;
Var B: Byte;
Begin
 B:=0;
 {$I-}BlockRead(OutF,B,1);{$I+}
 If IOResult<>0 Then FileOk:=False;
 RB:=B;
End;

Function RW: Integer;
Var V: LongInt;
Begin
 V:=RB;
 V:=V+LongInt(RB)*256;
 If V>32767 Then V:=V-65536;
 RW:=Integer(V);
End;

Function SaveNWC(Const Name: String): Boolean;
Var P,I,N: Integer; S: String;
Begin
 FileOk:=True;
 {$I-}
 Assign(OutF,Name);Rewrite(OutF,1);
 {$I+}
 If IOResult<>0 Then Begin SaveNWC:=False;Exit;End;
 S:='NWC1';
 BlockWrite(OutF,S[1],4);
 WW(NPg);
 For P:=1 To NPg Do Begin WB(NCol[P]);WB(Ord(HasHead[P]));End;
 WB(NFont);
 For I:=0 To NFont-1 Do Begin
  S:=FName[I];
  WB(Length(S));
  BlockWrite(OutF,S[1],Length(S));
  WW(FontHt(I));
 End;
 For P:=0 To NPg Do Begin
  N:=St[P].Len;
  WW(N);
  BlockWrite(OutF,St[P].T^,N+1);
  BlockWrite(OutF,St[P].F^,N+1);
  BlockWrite(OutF,St[P].A^,N+1);
 End;
 WW(NArt);
 For I:=1 To NArt Do Begin
  WB(Arts[I].Kind);WB(Arts[I].Flow);WB(Arts[I].FH);WB(Arts[I].FV);
  WB(Arts[I].Pat);WB(Arts[I].Th);
  WW(Arts[I].Lib);WW(Arts[I].Pg);WW(Arts[I].X);WW(Arts[I].Y);
  WW(Arts[I].W);WW(Arts[I].H);
  WW(Arts[I].SX1);WW(Arts[I].SY1);WW(Arts[I].SX2);WW(Arts[I].SY2);
 End;
 {$I-}Close(OutF);{$I+}
 If IOResult<>0 Then FileOk:=False;
 SaveNWC:=FileOk;
End;

Function LoadNWC(Const Name: String): Boolean;
Var P,I,N,NP,NF,L,K: Integer; S: String; Mg: String[4]; FMap: Array[0..MAXFONT]
  Of Byte;
    Nm: String; Ht: Integer; A: TArt;
Begin
 LoadNWC:=False;
 FileOk:=True;
 {$I-}
 Assign(OutF,Name);Reset(OutF,1);
 {$I+}
 If IOResult<>0 Then Exit;
 Mg[0]:=#4;
 {$I-}BlockRead(OutF,Mg[1],4);{$I+}
 If (IOResult<>0) Or (Mg<>'NWC1') Then Begin Close(OutF);Exit;End;
 NP:=RW;
 If (NP<1) Or (NP>MAXPG) Then Begin Close(OutF);Exit;End;
 For P:=1 To NP Do Begin NCol[P]:=RB;HasHead[P]:=RB<>0;If (NCol[P]<1) Or
   (NCol[P]>MAXCOL) Then NCol[P]:=1;End;
 NF:=RB;
 For I:=0 To NF-1 Do Begin
  L:=RB;
  If L>26 Then L:=26;
  Nm[0]:=Chr(L);
  If L>0 Then BlockRead(OutF,Nm[1],L);
  Ht:=RW;
  If I<=MAXFONT Then FMap[I]:=NearestFont(Nm,Ht);
 End;
 For P:=0 To NP Do Begin
  N:=RW;
  If (N<0) Or (N>St[P].Cap) Or Not FileOk Then Begin Close(OutF);Exit;End;
  {$I-}
  BlockRead(OutF,St[P].T^,N+1);
  BlockRead(OutF,St[P].F^,N+1);
  BlockRead(OutF,St[P].A^,N+1);
  {$I+}
  If IOResult<>0 Then Begin Close(OutF);Exit;End;
  St[P].Len:=N;
  For K:=0 To N Do If St[P].F^[K]<=MAXFONT Then St[P].F^[K]:=FMap[St[P].F^[K]];
 End;
 For P:=NP+1 To MAXPG Do StClear(P,DefHead,AL_CENTER);
 NPg:=NP;
 N:=RW;
 If (N<0) Or (N>MAXART) Then N:=0;
 NArt:=0;
 For I:=1 To N Do Begin
  FillChar(A,SizeOf(A),0);
  A.Kind:=RB;A.Flow:=RB;A.FH:=RB;A.FV:=RB;A.Pat:=RB;A.Th:=RB;
  A.Lib:=RW;A.Pg:=RW;A.X:=RW;A.Y:=RW;A.W:=RW;A.H:=RW;
  A.SX1:=RW;A.SY1:=RW;A.SX2:=RW;A.SY2:=RW;
  If (A.Pg>=1) And (A.Pg<=NPg) And ((A.Kind<>AR_ART) Or ((A.Lib>=1) And
    (A.Lib<=NLib))) Then Begin
   Inc(NArt);Arts[NArt]:=A;
  End;
 End;
 {$I-}Close(OutF);{$I+}
 If IOResult<>0 Then FileOk:=False;
 LoadNWC:=FileOk;
End;

{ ---- importation / exportation ASCII ---- }

Function ImportASCII(Const Name: String): Boolean;
Var F: File; Buf: Array[0..2047] Of Byte; Got: Word; I,NL: Integer; C: Byte;
    PrevCR,Full: Boolean; LastC: Byte;
Begin
 ImportASCII:=False;
 {$I-}
 Assign(F,Name);Reset(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 PushUndo;
 If SelA>=0 Then DelSel;
 NL:=0;PrevCR:=False;Full:=False;LastC:=13;
 If Cur>0 Then LastC:=St[ASt].T^[Cur-1];
 Repeat
  Got:=0;
  {$I-}BlockRead(F,Buf,SizeOf(Buf),Got);{$I+}
  If IOResult<>0 Then Got:=0;
  For I:=0 To Got-1 Do Begin
   C:=Buf[I];
   If C=13 Then Begin Inc(NL);PrevCR:=True;End
   Else If C=10 Then Begin
    If Not PrevCR Then Inc(NL);
    PrevCR:=False;
   End Else Begin
    PrevCR:=False;
    If C=9 Then C:=32;
    If C>=32 Then Begin
     If Not Full Then Begin
      If NL>=2 Then Begin
       If StIns(ASt,Cur,13,CurFont,AL_LEFT) Then Inc(Cur) Else Full:=True;
       LastC:=13;
      End Else If (NL=1) And (LastC<>32) And (LastC<>13) Then Begin
       If StIns(ASt,Cur,32,CurFont,0) Then Inc(Cur) Else Full:=True;
       LastC:=32;
      End;
      NL:=0;
      If Not ((C=32) And ((LastC=32) Or (LastC=13))) Then Begin
       If StIns(ASt,Cur,C,CurFont,0) Then Inc(Cur) Else Full:=True;
       LastC:=C;
      End;
     End;
    End;
   End;
  End;
 Until Got=0;
 Close(F);
 AfterEdit;
 If Full Then SetStatus('TEXTE TRONQU'#144);
 ImportASCII:=True;
End;

Function ExportASCII(Const Name: String): Boolean;
Var T: Text; P,I: Integer;
Begin
 ExportASCII:=False;
 {$I-}
 Assign(T,Name);Rewrite(T);
 {$I+}
 If IOResult<>0 Then Exit;
 For P:=1 To NPg Do
  If HasHead[P] And (St[P].Len>0) Then Begin
   For I:=0 To St[P].Len-1 Do
    If St[P].T^[I]=13 Then WriteLn(T) Else Write(T,Chr(St[P].T^[I]));
   WriteLn(T);WriteLn(T);
  End;
 For I:=0 To St[0].Len-1 Do
  If St[0].T^[I]=13 Then WriteLn(T) Else Write(T,Chr(St[0].T^[I]));
 WriteLn(T);
 Close(T);
 ExportASCII:=IOResult=0;
End;

{ ---- selecteur de fichier ---- }
Function FilePicker(Const Title,Mask: String; Var Name: String; Save: Boolean):
  Boolean;
Var Names: Array[1..80] Of String[12]; N,Sel,Top,I,J,X0,Y0,W,H,Rows,RowH:
  Integer;
    SR: SearchRec; E: TEvent; Done,Redraw: Boolean; S,T: String; LastT: LongInt;
      Ml: String;
Begin
 FilePicker:=False;
 FillChar(Names,SizeOf(Names),0);
 N:=0;
 Ml:=Mask;
 For J:=1 To 2 Do Begin
  FindFirst(Ml,AnyFile,SR);
  While (DosError=0) And (N<80) Do Begin
   If (SR.Attr And Directory)=0 Then Begin
    T:=Upper(SR.Name);
    I:=1;
    While (I<=N) And (Names[I]<>T) Do Inc(I);
    If I>N Then Begin Inc(N);Names[N]:=T;End;
   End;
   FindNext(SR);
  End;
  {$IFDEF FPC}FindClose(SR);{$ENDIF}
  Ml:=Mask;
  For I:=1 To Length(Ml) Do Ml[I]:=LowerCase(Ml[I]);
 End;
 For I:=1 To N-1 Do
  For J:=I+1 To N Do
   If Names[J]<Names[I] Then Begin T:=Names[I];Names[I]:=Names[J];Names[J]:=T;
     End;
 Sel:=0;Top:=0;Rows:=10;RowH:=13;
 W:=360;H:=Rows*RowH+TBH+86;
 X0:=(SCR_W-W) Div 2;Y0:=(SCR_H-H) Div 2-6;
 S:=Name;LastT:=0;
 Done:=False;Redraw:=True;
 Repeat
  If Sel<Top Then Top:=Sel;
  If Sel>=Top+Rows Then Top:=Sel-Rows+1;
  If Top<0 Then Top:=0;
  If Redraw Then Begin
   HideMouse;
   DlgFrame(X0,Y0,W,H,Title);
   PText(X0+14,Y0+TBH+10,Tr('Fichier :'));
   Box(X0+80,Y0+TBH+6,X0+W-14,Y0+TBH+22,PAPER);
   Frame(X0+80,Y0+TBH+6,X0+W-14,Y0+TBH+22);
   PText(X0+84,Y0+TBH+10,S);
   Line(X0+84+TextW(S),Y0+TBH+8,X0+84+TextW(S),Y0+TBH+20);
   Box(X0+14,Y0+TBH+30,X0+W-14,Y0+TBH+32+Rows*RowH,PAPER);
   Frame(X0+14,Y0+TBH+30,X0+W-14,Y0+TBH+32+Rows*RowH);
   If N=0 Then PText(X0+20,Y0+TBH+36,Tr('(aucun fichier ')+Mask+')');
   For I:=0 To Rows-1 Do
    If Top+I+1<=N Then Begin
     If Top+I+1=Sel Then Begin
      Box(X0+15,Y0+TBH+31+I*RowH,X0+W-15,Y0+TBH+31+(I+1)*RowH,INK);
      WText(X0+20,Y0+TBH+34+I*RowH,Names[Top+I+1]);
     End Else PText(X0+20,Y0+TBH+34+I*RowH,Names[Top+I+1]);
    End;
   Button(X0+W-190,Y0+H-34,X0+W-110,Y0+H-14,'OK',True,True);
   Button(X0+W-96,Y0+H-34,X0+W-16,Y0+H-14,'&Annuler',False,True);
   ShowMouse;
   Redraw:=False;
  End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   Case E.Key Of
    K_ESC: Done:=True;
    K_ENTER: If S<>'' Then Begin Name:=Upper(S);FilePicker:=True;Done:=True;End;
    K_UP: If Sel>1 Then Begin Dec(Sel);S:=Names[Sel];Redraw:=True;End;
    K_DOWN: If Sel<N Then Begin Inc(Sel);S:=Names[Sel];Redraw:=True;End;
    K_PGUP: If N>0 Then Begin Sel:=Sel-Rows;If Sel<1 Then Sel:=1;S:=Names[Sel];
      Redraw:=True;End;
    K_PGDN: If N>0 Then Begin Sel:=Sel+Rows;If Sel>N Then Sel:=N;S:=Names[Sel];
      Redraw:=True;End;
    K_BKSP: If Length(S)>0 Then Begin Dec(S[0]);Sel:=0;Redraw:=True;End;
    33..126: If Length(S)<40 Then Begin S:=S+Chr(E.Key);Sel:=0;Redraw:=True;End;
   End;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X0+14,Y0+TBH+31,X0+W-14,Y0+TBH+31+Rows*RowH) Then Begin
    I:=Top+Integer((E.Y-(Y0+TBH+31)) Div RowH)+1;
    If (I>=1) And (I<=N) Then Begin
     If (I=Sel) And (Tick-LastT<40) Then Begin Name:=Names[I];FilePicker:=True;
       Done:=True;End;
     Sel:=I;S:=Names[I];Redraw:=True;LastT:=Tick;
    End;
   End Else If InBox(E.X,E.Y,X0+W-190,Y0+H-34,X0+W-110,Y0+H-14) Then Begin
    If S<>'' Then Begin Name:=Upper(S);FilePicker:=True;Done:=True;End;
   End Else If InBox(E.X,E.Y,X0+W-96,Y0+H-34,X0+W-16,Y0+H-14) Then Done:=True
   Else If InBox(E.X,E.Y,X0+3,Y0+3,X0+22,Y0+TBH) Then Done:=True;
  End;
 Until Done;
 NeedDraw:=True;
End;

{ ====================================================================== }
{                  IMPRESSION : EXPORT D'UNE PAGE EN PBM                 }
{ ====================================================================== }

Function ExportPagePBM(P: Integer; Const FN: String): Boolean;
Var F: File; Hdr: String; BandY,R,Y,X,TX,BPR: Integer; Buf: PBytes;
    SvN,SvD: Integer; I: Integer; X0,Y0: LongInt;
Begin
 ExportPagePBM:=False;
 BPR:=(PGW+7) Div 8;
 GetMem(Buf,BPR*VH);
 {$I-}
 Assign(F,FN);Rewrite(F,1);
 {$I+}
 If IOResult<>0 Then Begin FreeMem(Buf,BPR*VH);Exit;End;
 Hdr:='P4'#10+IntStr(PGW)+' '+IntStr(PGH)+#10;
 BlockWrite(F,Hdr[1],Length(Hdr));
 SvN:=ZN;SvD:=ZD;ZN:=1;ZD:=1;
 BandY:=0;
 While BandY<PGH Do Begin
  R:=VH;
  If BandY+R>PGH Then R:=PGH-BandY;
  FillChar(Buf^,BPR*VH,0);
  For TX:=0 To 1 Do Begin
   SetViewPort(0,0,VW-1,VH-1,True);
   SetFillStyle(SolidFill,PAPER);LastFill:=-1;
   Bar(0,0,VW-1,VH-1);
   X0:=-TX*VW;Y0:=-BandY;
   DrawLinesOfPage(P,X0,Y0);
   For I:=1 To NArt Do
    If Arts[I].Pg=P Then DrawArtItem(I,X0,Y0,False);
   For Y:=0 To R-1 Do
    For X:=0 To VW-1 Do
     If TX*VW+X<PGW Then
      If GetPixel(X,Y)=INK Then
       Buf^[Y*BPR+((TX*VW+X) Shr 3)]:=Buf^[Y*BPR+((TX*VW+X) Shr 3)] Or ($80 Shr
         ((TX*VW+X) And 7));
  End;
  BlockWrite(F,Buf^,BPR*R);
  BandY:=BandY+VH;
 End;
 Close(F);
 ZN:=SvN;ZD:=SvD;
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 FreeMem(Buf,BPR*VH);
 ExportPagePBM:=IOResult=0;
End;

Procedure CmdPrint(All: Boolean);
Var P1,P2,P: Integer; Base,FN: String; Ok: Boolean;
Begin
 If DocName<>'' Then Base:=NoExt(ShortName(DocName)) Else Base:='NEWS';
 If All Then Begin P1:=1;P2:=NPg;End Else Begin P1:=CurPage;P2:=CurPage;End;
 Ok:=True;
 For P:=P1 To P2 Do Begin
  FN:=Copy(Base,1,6)+Chr(48+P Div 10)+Chr(48+P Mod 10)+'.PBM';
  HideMouse;
  Box(160,200,480,250,PAPER);Frame(160,200,480,250);Frame(162,202,478,248);
  BText(180,220,Tr('Impression de la page ')+IntStr(P)+' ...');
  ShowMouse;
  If Not ExportPagePBM(P,FN) Then Ok:=False;
 End;
 NeedDraw:=True;
 If Ok Then Begin
  If P1=P2 Then MsgBox('Impression',
    Tr('Page ')+IntStr(P1)+Tr(' enregistr'#130'e dans ')+Copy(Base,1,
    6)+Chr(48+P1 Div 10)+Chr(48+P1 Mod 10)+'.PBM')
  Else MsgBox('Impression',Tr('Pages enregistr'#130'es : ')+Copy(Base,1,
    6)+'01.PBM ...|'+Tr('Format : bitmap PBM ')+IntStr(PGW)+' x '+IntStr(PGH))
 End Else MsgBox('Impression','Erreur d'''#130'criture du fichier.');
End;

{ ====================================================================== }
{                       COMMANDES DE DOCUMENT                            }
{ ====================================================================== }

Procedure ResetDoc;
Var P: Integer;
Begin
 NPg:=1;
 For P:=1 To MAXPG Do Begin NCol[P]:=2;HasHead[P]:=False;End;
 HasHead[1]:=True;
 For P:=0 To MAXPG Do StClear(P,DefHead,AL_CENTER);
 StClear(0,DefBody,AL_LEFT);
 StAppend(1,Tr('Titre du journal'),DefHead);
 NArt:=0;SelArt:=0;HeldOn:=False;ArtSub:=0;DrawStep:=0;
 DocName:='';Named:=False;Modified:=False;
 ASt:=0;Cur:=0;SelA:=-1;MarkMode:=False;CurFont:=DefBody;TypRun:=False;
 UndoOK:=False;CurPage:=1;ScrX:=0;ScrY:=0;WantX:=-1;
 ACx:=MRG+20;ACy:=MRG+HEADH+30;
 Relayout;
End;

Function FontOr(Const Nm: String; Def: Integer): Integer;
Var F: Integer;
Begin
 F:=FontByName(Nm);
 If F<0 Then F:=Def;
 FontOr:=F;
End;

Procedure MakeDemo;
Var FB,FH,FT: Integer; A: TArt;
Begin
 ResetDoc;
 If UseFLB Then Begin
  FH:=FontOr('News 24 bold',DefHead);
  FT:=FontOr('Park 12 bold',DefBody);
  FB:=FontOr('Park 12',DefBody);
 End Else Begin
  FH:=FontOr('Titre 32',DefHead);
  FT:=FontOr('Systeme 16 gras',DefBody);
  FB:=FontOr('Systeme 8',DefBody);
 End;
 StClear(1,FH,AL_CENTER);
 StAppend(1,Tr('CRAZY JOE''S FISH SHACK'),FH);
 StAppend(0,
   Tr('Attrapez nos portions de taille BALEINE '#133' prix de sardine !')+#13,
   FT);
 St[0].A^[St[0].Len-1]:=AL_CENTER;
 StAppend(0,#13,FB);
 StAppend(0,Tr('Sp'#130'cial du jour')+#13,FT);
 StAppend(0,
   Tr('Flet frit : 5,25 $. Notre cuisinier, un ancien marin au grand coeur, '),
   FB);
 StAppend(0,Tr('pr'#130'pare chaque matin le poisson le plus frais du port. '),
   FB);
 StAppend(0,
   Tr('Servi avec des frites maison, une salade croquante et la fameuse sauce '+
   'secr'#138'te de la maison.')+#13,FB);
 StAppend(0,#13,FB);
 StAppend(0,
   Tr('Chaudr'#130'e de palourdes : 3,95 $. Une soupe onctueuse '#133' la '+
   'cr'#138'me, '),FB);
 StAppend(0,
   Tr('garnie de palourdes, de pommes de terre et de lard fum'#130'. '+
   'Id'#130'ale '),FB);
 StAppend(0,
   Tr('pour r'#130'chauffer les journ'#130'es d''hiver sur le quai.')+#13,FB);
 StAppend(0,#13,FB);
 StAppend(0,Tr('Plateau de fruits de mer : 7,99 $. '),FB);
 StAppend(0,
   Tr('Crevettes, p'#130'tonles, calmars et moules, accompagn'#130's de '+
   'citron et de beurre fondu. '),FB);
 StAppend(0,
   Tr('Le plateau est servi sur glace pour garder toute la fra'#139'cheur de '+
   'la mer. '),FB);
 StAppend(0,Tr('Venez nombreux, la maison offre le caf'#130' !')+#13,FB);
 St[0].A^[St[0].Len]:=AL_LEFT;
 FillChar(A,SizeOf(A),0);
 A.Kind:=AR_ART;A.Lib:=1;A.Pg:=1;A.Flow:=FL_BOTH;
 A.X:=PGW Div 2-48;A.Y:=MRG+HEADH+24;A.W:=96;A.H:=96;
 A.SX1:=0;A.SY1:=0;A.SX2:=Lib[1].W;A.SY2:=Lib[1].H;
 AddArt(A);
 A.Lib:=2;A.X:=PGW-MRG-90;A.Y:=PGH-MRG-130;A.W:=90;A.H:=68;
 A.SX2:=Lib[2].W;A.SY2:=Lib[2].H;A.Flow:=FL_BOTH;
 AddArt(A);
 Modified:=False;
 Relayout;
End;

Function ConfirmLose: Boolean;
Begin
 If Not Modified Then ConfirmLose:=True
 Else ConfirmLose:=ConfirmBox('Les changements non enregistr'#130's seront '+
   'perdus. Continuer ?');
End;

Procedure CmdNew;
Begin
 If Not ConfirmLose Then Exit;
 ResetDoc;
 SetPanel(MD_MAIN);
 SetView(2);
End;

Procedure CmdOpen;
Var N: String;
Begin
 If Not ConfirmLose Then Exit;
 N:='';
 If Not FilePicker('Ouvrir un journal','*.NWC',N,False) Then Exit;
 N:=AddExt(N,'NWC');
 If Not FileExists(N) Then Begin MsgBox('Ouvrir',
   Tr('Fichier introuvable : ')+N);Exit;End;
 If LoadNWC(N) Then Begin
  DocName:=N;Named:=True;Modified:=False;
  ASt:=0;Cur:=0;SelA:=-1;SelArt:=0;HeldOn:=False;UndoOK:=False;CurPage:=1;
    ScrX:=0;ScrY:=0;
  CurFont:=St[0].F^[0];
  Relayout;
  SetView(ViewNo);
  SetStatus('JOURNAL CHARG'#144);
 End Else Begin
  MsgBox('Ouvrir','Ce fichier n''est pas un journal NewsMaster valide.');
  ResetDoc;
 End;
End;

Procedure CmdSaveAs;
Var N: String;
Begin
 N:=DocName;
 If Not FilePicker('Enregistrer le journal','*.NWC',N,True) Then Exit;
 N:=AddExt(N,'NWC');
 If FileExists(N) Then
  If Not ConfirmBox(Tr('Le fichier ')+ShortName(N)+Tr(' existe. Le remplacer '+
    '?')) Then Exit;
 If SaveNWC(N) Then Begin
  DocName:=N;Named:=True;Modified:=False;
  SetStatus('JOURNAL ENREGISTR'#144);
 End Else MsgBox('Enregistrer','Erreur d'''#130'criture du fichier.');
End;

Procedure CmdSave;
Begin
 If Not Named Then Begin CmdSaveAs;Exit;End;
 If SaveNWC(DocName) Then Begin Modified:=False;
   SetStatus('JOURNAL ENREGISTR'#144);End
 Else MsgBox('Enregistrer','Erreur d'''#130'criture du fichier.');
End;

Procedure CmdImport;
Var N: String;
Begin
 N:='';
 If Not FilePicker('Importer du texte ASCII','*.TXT',N,False) Then Exit;
 If Not FileExists(N) Then N:=AddExt(N,'TXT');
 If Not FileExists(N) Then Begin MsgBox('Importer',
   Tr('Fichier introuvable : ')+N);Exit;End;
 If Mode<>MD_TEXT Then SetPanel(MD_TEXT);
 If Not ImportASCII(N) Then MsgBox('Importer',Tr('Impossible de lire ')+N);
End;

Procedure CmdExport;
Var N: String;
Begin
 N:='NEWS.TXT';
 If Not FilePicker('Exporter le texte ASCII','*.TXT',N,True) Then Exit;
 N:=AddExt(N,'TXT');
 If ExportASCII(N) Then SetStatus('TEXTE EXPORT'#144) Else
   MsgBox('Exporter','Erreur d'''#130'criture du fichier.');
End;

Procedure CmdQuit;
Begin
 If Modified Then Begin
  If ConfirmBox('Quitter NewsMaster ? Les changements seront perdus.') Then
    Quit:=True;
 End Else If ConfirmBox('Quitter NewsMaster ?') Then Quit:=True;
 NeedDraw:=True;
End;

Procedure CmdGoto;
Var S: String; V: LongInt;
Begin
 S:=IntStr(CurPage);
 If InputBox(#133' la page','Num'#130'ro de page :',S,3) Then Begin
  V:=ValInt(S,CurPage);
  GotoPage(Integer(V));
 End;
End;

Procedure CmdAbout;
Begin
 MsgBox(#192' propos de NewsMaster',
   Tr('NewsMaster - Clone Pascal')+'|'+Tr('Programme de publication de '+
   'journaux')+'|Version '+VERSION_TEXT+' - OFFICE-0|'+Tr('Inspir'#130' de '+
   'News Master (Unison World, 1986)')+'|https://www.gladir.com/office-0');
End;

Procedure CmdStats;
Var I,Tx,Ar: LongInt; S: String;
Begin
 Tx:=St[0].Len;
 Ar:=NArt;
 S:=Tr('Pages : ')+IntStr(NPg)+'|'+Tr('Texte principal : ')+IntStr(Tx)+Tr(' '+
   'caract'#138'res')+'|';
 S:=S+Tr('Images et traits : ')+IntStr(Ar)+'|'+Tr('Polices disponibles '+
   ': ')+IntStr(NFont);
 If UseFLB Then S:=S+' (NEWS.FLB)' Else S:=S+Tr(' (int'#130'gr'#130'es)');
 If Overflow Then
   S:=S+'|'+Tr('ATTENTION : du texte d'#130'passe la mise en page');
 MsgBox('Statistiques',S);
End;

Procedure CmdFreeMem;
Begin
 {$IFDEF FPC}
 MsgBox('M'#130'moire','M'#130'moire g'#130'r'#130'e par Free Pascal.');
 {$ELSE}
 MsgBox('M'#130'moire',Tr('Plus grand bloc libre : ')+IntStr(MaxAvail Div
   1024)+' Ko|'+Tr('M'#130'moire libre : ')+IntStr(MemAvail Div 1024)+' Ko');
 {$ENDIF}
End;

{ Change la source des polices (NEWS.FLB ou polices integrees) }
Procedure SwitchFonts(NewFLB: Boolean);
Var OldN,I,S,K: Integer; OldName: Array[0..MAXFONT-1] Of String[26];
    OldHt: Array[0..MAXFONT-1] Of Integer; Map: Array[0..MAXFONT-1] Of Byte;
Begin
 OldN:=NFont;
 For I:=0 To OldN-1 Do Begin OldName[I]:=FName[I];OldHt[I]:=FontHt(I);End;
 UseFLB:=NewFLB;
 BuildFontTable;
 For I:=0 To OldN-1 Do Map[I]:=NearestFont(OldName[I],OldHt[I]);
 For S:=0 To MAXPG Do
  For K:=0 To St[S].Len Do
   If St[S].F^[K]<OldN Then St[S].F^[K]:=Map[St[S].F^[K]] Else
     St[S].F^[K]:=DefBody;
 For K:=0 To ClipN-1 Do
  If ClipF^[K]<OldN Then ClipF^[K]:=Map[ClipF^[K]] Else ClipF^[K]:=DefBody;
 If CurFont<OldN Then CurFont:=Map[CurFont] Else CurFont:=DefBody;
 UndoOK:=False;
 Relayout;
End;

{ ====================================================================== }
{                        COMMANDES DU PANNEAU                            }
{ ====================================================================== }

Procedure MainMenuLoop; Forward;

Procedure PanelKey(N: Integer);
Begin
 If (N<1) Or (N>NPB) Then Exit;
 Case Mode Of
  MD_MAIN: Case N Of
    1: SetPanel(MD_VIEW);
    2: Begin SetPanel(MD_TEXT);Moved;End;
    3: Begin SetPanel(MD_ART);UpdateSelArt;End;
    4: Begin SetPanel(MD_LAYOUT);End;
    5: SetPanel(MD_FILE);
    6: SetPanel(MD_PRINT);
   End;
  MD_VIEW: Case N Of
    1..4: SetView(N);
    5: GotoPage(CurPage-1);
    6: GotoPage(CurPage+1);
   End;
  MD_TEXT: Case N Of
    1: CmdFont;
    2: CmdAlignPopup;
    3: ToggleMark;
    4: ClipCut;
    5: ClipCopy;
    6: ClipPaste;
    7: CmdImport;
    8: DoUndo;
   End;
  MD_ART: Case N Of
    1: CmdChooseArt;
    2: PickUp(False);
    3: PickUp(True);
    4: StampHeld;
    5: If TargetOk Then Begin
        If ArtSub=1 Then ArtSub:=0 Else ArtSub:=1;
        NeedDraw:=True;
       End;
    6: If TargetOk Then Begin
        If ArtSub=2 Then ArtSub:=0 Else ArtSub:=2;
        NeedDraw:=True;
       End;
    7: If TargetOk Then Begin
        If HeldOn Then N:=PopupAt(8+6*62,PANEL_Y-80,190,2,Held.Flow+1)
        Else N:=PopupAt(8+6*62,PANEL_Y-80,190,2,Arts[SelArt].Flow+1);
        If N>0 Then ArtSetFlow(N-1);
       End;
    8: If TargetOk Then Begin
        N:=PopupAt(8+7*62,PANEL_Y-50,150,5,1);
        If N>0 Then ArtFlip(N=1);
       End;
    9: CmdDrawTool;
    10: If SelArt>0 Then DelArt(SelArt) Else If HeldOn Then Begin HeldOn:=False;
      NeedDraw:=True;End;
   End;
  MD_LAYOUT: Case N Of
    1: CmdAddCol;
    2: CmdDelCol;
    3: CmdAddHead;
    4: CmdDelHead;
    5: CmdAddPage;
    6: CmdDelPage;
   End;
  MD_FILE: Case N Of
    1: CmdNew;
    2: CmdOpen;
    3: CmdSave;
    4: CmdSaveAs;
    5: MainMenuLoop;
    6: CmdQuit;
   End;
  MD_PRINT: Case N Of
    1: CmdPrint(False);
    2: CmdPrint(True);
    3: CmdExport;
   End;
 End;
 NeedDraw:=True;
End;

Procedure DoMenu(M,I: Integer);
Var A,B: Integer;
Begin
 Case M Of
  1: Case I Of
      1: CmdAbout;
      3: CmdStats;
      4: CmdFreeMem;
     End;
  2: Case I Of
      1: MainMenuLoop;
      2: CmdNew;
      3: CmdOpen;
      4: CmdSave;
      5: CmdSaveAs;
      7: CmdImport;
      8: CmdExport;
      10: CmdPrint(False);
      11: CmdPrint(True);
      13: CmdQuit;
     End;
  3: Case I Of
      1: DoUndo;
      3: ClipCut;
      4: ClipCopy;
      5: ClipPaste;
      6: If SelRange(A,B) Then Begin PushUndo;DelSel;AfterEdit;End;
      7: Begin If Mode<>MD_TEXT Then SetPanel(MD_TEXT);SelectAll;End;
      9: CmdFind;
      10: FindNextText;
     End;
  4: Case I Of
      1: Begin If Mode<>MD_TEXT Then SetPanel(MD_TEXT);CmdFont;End;
      2: CmdFontStep(-1);
      3: CmdFontStep(1);
      5..8: SetAlign(I-5);
      10: Begin If Mode<>MD_TEXT Then SetPanel(MD_TEXT);ToggleMark;End;
      11: Begin SetPanel(MD_TEXT);Moved;End;
     End;
  5: Case I Of
      1: Begin SetPanel(MD_ART);UpdateSelArt;End;
      3: CmdChooseArt;
      4: PickUp(False);
      5: PickUp(True);
      6: StampHeld;
      7: If SelArt>0 Then DelArt(SelArt);
      9..13: ArtSetFlow(I-9);
      15: ArtResize(ACStep,ACStep);
      16: ArtResize(-ACStep,-ACStep);
      17: ArtResetSize;
      18: ArtFlip(True);
      19: ArtFlip(False);
      21: Begin DrawKind:=AR_LINE;ArtSub:=3;DrawStep:=0;HeldOn:=False;
           If Mode<>MD_ART Then SetPanel(MD_ART);NeedDraw:=True;End;
      22: Begin DrawKind:=AR_BOX;ArtSub:=3;DrawStep:=0;HeldOn:=False;
           If Mode<>MD_ART Then SetPanel(MD_ART);NeedDraw:=True;End;
      23: CmdPattern;
      24: CmdThickness;
     End;
  6: Case I Of
      1: SetPanel(MD_LAYOUT);
      3: CmdAddCol;
      4: CmdDelCol;
      5: CmdAddHead;
      6: CmdDelHead;
      8: CmdAddPage;
      9: CmdDelPage;
      11: GotoPage(CurPage-1);
      12: GotoPage(CurPage+1);
      13: CmdGoto;
     End;
  7: Case I Of
      1..4: SetView(I);
      6: ACStep:=16;
      7: ACStep:=4;
      8: ACStep:=1;
     End;
  8: Case I Of
      1: If FLBFound Then SwitchFonts(Not UseFLB);
      2: GuidesOn:=Not GuidesOn;
      3: CmdAbout;
     End;
 End;
 NeedDraw:=True;
End;

{ ====================================================================== }
{                          AFFICHAGE GLOBAL                              }
{ ====================================================================== }

Procedure DrawAll;
Begin
 NeedDraw:=False;
 HideMouse;
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 SetLineStyle(SolidLn,0,1);
 LastFill:=-1;
 If Mode=MD_LAYOUT Then DrawLayoutScreen
 Else Begin
  DrawViewArea;
  DrawPanel;
 End;
 DrawMenuBar;
 If MenuOpen>0 Then DrawDropDown;
 ShowMouse;
End;

{ ====================================================================== }
{                        ECRANS D'ACCUEIL                                }
{ ====================================================================== }

Procedure CenterText(F,Y,X1,X2: Integer; Const S: String);
Begin
 DrawStrF(F,(X1+X2-StrWidthF(F,S)) Div 2,Y,S);
End;

Procedure ShowSplash;
Var F,FB,Y,I,W,X1,X2,Y2,LH,PW: Integer; E: TEvent; T0: LongInt; Ln: Array[1..4]
  Of String;
    Pr: String;
Begin
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 PatBar(0,0,SCR_W-1,SCR_H-1,PatStripe);
 If UseFLB Then Begin F:=FontOr('Park 12 bold',DefBody);
   FB:=FontOr('News 18 bold',DefHead);End
 Else Begin F:=FontOr('Systeme 16 gras',DefBody);FB:=FontOr('Titre 32',DefHead);
   End;
 Ln[1]:=Tr('NEWSMASTER - CLONE VERSION ')+VERSION_TEXT;
 Ln[2]:=Tr('PROGRAMME DE PUBLICATION DE JOURNAUX');
 Ln[3]:=Tr('D''APRES NEWS MASTER (UNISON WORLD, 1986)');
 Ln[4]:=Tr('OFFICE-0 - WWW.GLADIR.COM');
 { la boite s'adapte a la largeur du texte le plus long }
 W:=StrWidthF(FB,'NEWSMASTER');
 For I:=1 To 4 Do If StrWidthF(F,Ln[I])>W Then W:=StrWidthF(F,Ln[I]);
 W:=W+80;
 If W<360 Then W:=360;
 If W>SCR_W-16 Then W:=SCR_W-16;
 X1:=(SCR_W-W) Div 2;X2:=X1+W;
 LH:=FAsc[F]+FDsc[F]+6;
 Y:=108+FAsc[FB]+FDsc[FB]+14;
 Y2:=Y+4*LH+16;
 Box(X1+5,90+5,X2+5,Y2+5,INK);
 Box(X1,90,X2,Y2,PAPER);
 Frame(X1,90,X2,Y2);Frame(X1+4,94,X2-4,Y2-4);
 CenterText(FB,108,X1,X2,'NEWSMASTER');
 For I:=1 To 4 Do Begin
  CenterText(F,Y,X1,X2,Ln[I]);
  Y:=Y+LH;
 End;
 Pr:=Tr('APPUYEZ SUR ESPACE POUR CONTINUER');
 PW:=TextW(Pr)+60;
 LabelBox((SCR_W-PW) Div 2,Y2+40,(SCR_W+PW) Div 2,Y2+64,Pr);
 T0:=Tick;
 Repeat
  PollEvent(E);
 Until ((E.Kind=1)) Or (E.Kind=2) Or (Abs(Tick-T0)>1500);
End;

Procedure MainMenuLoop;
Var Sel,I,X0,Y0,W,H,N: Integer; E: TEvent; Done,Redraw: Boolean;
Begin
 Sel:=2;N:=4;
 W:=420;H:=TBH+190;
 X0:=(SCR_W-W) Div 2;Y0:=(SCR_H-H) Div 2+6;
 Done:=False;Redraw:=True;
 Repeat
  If Redraw Then Begin
   HideMouse;
   SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
   PatBar(0,MENU_H,SCR_W-1,SCR_H-1,PatStripe);
   DlgFrame(X0,Y0,W,H,'NewsMaster : Menu principal');
   PText(X0+20,Y0+TBH+14,Tr('Choisissez une activit'#130' :'));
   For I:=1 To N Do Begin
    If I=Sel Then Begin
     Box(X0+20,Y0+TBH+34+(I-1)*30,X0+W-20,Y0+TBH+58+(I-1)*30,INK);
     WText(X0+32,Y0+TBH+42+(I-1)*30,IntStr(I)+'. '+Tr(ListMain(I)));
    End Else Begin
     Frame(X0+20,Y0+TBH+34+(I-1)*30,X0+W-20,Y0+TBH+58+(I-1)*30);
     PText(X0+32,Y0+TBH+42+(I-1)*30,IntStr(I)+'. '+Tr(ListMain(I)));
    End;
   End;
   DrawMenuBar;
   ShowMouse;
   Redraw:=False;
  End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   Case E.Key Of
    K_ESC: Done:=True;
    K_UP: Begin If Sel>1 Then Dec(Sel) Else Sel:=N;Redraw:=True;End;
    K_DOWN: Begin If Sel<N Then Inc(Sel) Else Sel:=1;Redraw:=True;End;
    49..52: Begin Sel:=E.Key-48;E.Key:=K_ENTER;End;
   End;
   If E.Key=K_ENTER Then Begin
    Case Sel Of
     1: If ConfirmLose Then Begin ResetDoc;Done:=True;End;
     2: Done:=True;
     3: Begin CmdOpen;If Named Then Done:=True;End;
     4: Begin CmdQuit;If Quit Then Done:=True;End;
    End;
    Redraw:=True;
   End;
  End Else If E.Kind=2 Then Begin
   If E.Y<MENU_H Then Begin
    I:=TitleHit(E.X,E.Y);
    If I>0 Then Begin RunMenu(I,True);Redraw:=True;If Mode<>MD_MAIN Then
      Done:=True;End;
   End;
   For I:=1 To N Do
    If InBox(E.X,E.Y,X0+20,Y0+TBH+34+(I-1)*30,X0+W-20,Y0+TBH+58+(I-1)*30) Then
      Begin
     Sel:=I;
     Case Sel Of
      1: If ConfirmLose Then Begin ResetDoc;Done:=True;End;
      2: Done:=True;
      3: Begin CmdOpen;If Named Then Done:=True;End;
      4: Begin CmdQuit;If Quit Then Done:=True;End;
     End;
     Redraw:=True;
    End;
  End;
 Until Done Or Quit;
 SetPanel(MD_MAIN);
 SetView(ViewNo);
 NeedDraw:=True;
End;

{ ====================================================================== }
{                              CLAVIER                                   }
{ ====================================================================== }

Function AltLetter(K: Word): Integer;
Const
 RowQ : String[10] = 'QWERTYUIOP';
 RowA : String[9] = 'ASDFGHJKL';
 RowZ : String[7] = 'ZXCVBNM';
Var Sc_: Integer;
Begin
 AltLetter:=-1;
 If K<256 Then Exit;
 Sc_:=K-256;
 Case Sc_ Of
  16..25: AltLetter:=Ord(RowQ[Sc_-15])-65;
  30..38: AltLetter:=Ord(RowA[Sc_-29])-65;
  44..50: AltLetter:=Ord(RowZ[Sc_-43])-65;
 End;
End;

Procedure MenuByLetter(L: Integer);
Var M: Integer;
Begin
 M:=0;
 Case Chr(L+65) Of
  'N': M:=1;
  'F': M:=2;
  'E': M:=3;
  'T': M:=4;
  'I': M:=5;
  'P': M:=6;
  'V': M:=7;
  'O': M:=8;
 End;
 If M>0 Then RunMenu(M,False);
End;

Procedure ScrollKeys(K: Word);
Begin
 Case K Of
  K_UP: ScrollBy(0,-24);
  K_DOWN: ScrollBy(0,24);
  K_LEFT: ScrollBy(-24,0);
  K_RIGHT: ScrollBy(24,0);
  K_PGUP: ScrollBy(0,-(VH-30));
  K_PGDN: ScrollBy(0,VH-30);
  K_HOME: Begin ScrX:=0;ScrY:=0;ClampScroll;NeedDraw:=True;End;
  K_END: Begin ScrY:=DocHpx;ClampScroll;NeedDraw:=True;End;
 End;
End;

Procedure TextKey(K: Word);
Var I,N: Integer;
Begin
 Case K Of
  K_ENTER: TypeChar(13);
  K_TAB: Begin TypeChar(32);TypeChar(32);TypeChar(32);TypeChar(32);End;
  K_BKSP: DoBackspace;
  K_DEL: DoDelete;
  K_LEFT: MoveTo(Cur-1);
  K_RIGHT: MoveTo(Cur+1);
  K_UP: CurUpDown(-1);
  K_DOWN: CurUpDown(1);
  K_HOME: CurLineEdge(True);
  K_END: CurLineEdge(False);
  K_CHOME: MoveTo(0);
  K_CEND: MoveTo(St[ASt].Len);
  K_PGUP: For I:=1 To 12 Do CurUpDown(-1);
  K_PGDN: For I:=1 To 12 Do CurUpDown(1);
  32..255: TypeChar(K);
 End;
 N:=0;
End;

Procedure ArtKey(K: Word);
Begin
 Case ArtSub Of
  1: Case K Of
      K_RIGHT: ArtResize(ACStep,0);
      K_LEFT: ArtResize(-ACStep,0);
      K_UP: ArtResize(0,-ACStep);
      K_DOWN: ArtResize(0,ACStep);
      43: ArtResize(ACStep,ACStep);
      45: ArtResize(-ACStep,-ACStep);
      K_HOME: ArtResetSize;
      K_ENTER,K_ESC: Begin ArtSub:=0;NeedDraw:=True;End;
     End;
  2: Case K Of
      K_RIGHT: ArtCrop(1,0);
      K_LEFT: ArtCrop(-1,0);
      K_UP: ArtCrop(0,-1);
      K_DOWN: ArtCrop(0,1);
      K_TAB: Begin CropEnd:=1-CropEnd;NeedDraw:=True;End;
      K_ENTER,K_ESC: Begin ArtSub:=0;NeedDraw:=True;End;
     End;
 Else
  Case K Of
   K_LEFT: ArtCursorMove(-1,0);
   K_RIGHT: ArtCursorMove(1,0);
   K_UP: ArtCursorMove(0,-1);
   K_DOWN: ArtCursorMove(0,1);
   K_PGUP: ArtCursorMove(0,-(VH Div ACStep));
   K_PGDN: ArtCursorMove(0,VH Div ACStep);
   K_ENTER: Begin
     If ArtSub=3 Then Begin
      If DrawStep=0 Then Begin
       DrawStep:=1;DrawX0:=ACx;DrawY0:=ACy;
       SetStatus('ENTR'#144'E : POINT FINAL');
      End Else Begin ArtFinishDraw;SetStatus('OBJET AJOUT'#144);End;
     End Else If HeldOn Then StampHeld
     Else If SelArt>0 Then PickUp(False);
     NeedDraw:=True;
    End;
   K_DEL: If SelArt>0 Then DelArt(SelArt);
   K_TAB: Begin CropEnd:=1-CropEnd;End;
   43: ArtResize(ACStep,ACStep);
   45: ArtResize(-ACStep,-ACStep);
  End;
 End;
End;

Procedure HandleKey(K: Word);
Var L: Integer;
Begin
 If K>=256 Then Begin
  L:=AltLetter(K);
  If L>=0 Then Begin MenuByLetter(L);Exit;End;
 End;
 If (K>=K_F1) And (K<=K_F1+9) Then Begin PanelKey(K-K_F1+1);Exit;End;
 { raccourcis control }
 Case K Of
  14: Begin CmdNew;Exit;End;
  15: Begin CmdOpen;Exit;End;
  17: Begin CmdQuit;Exit;End;
  19: Begin CmdSave;Exit;End;
  26: Begin DoUndo;Exit;End;
  6: Begin CmdFind;Exit;End;
  7: Begin FindNextText;Exit;End;
  20: Begin If Mode<>MD_TEXT Then SetPanel(MD_TEXT);CmdFont;Exit;End;
 End;
 If Mode=MD_TEXT Then Begin
  Case K Of
   1: Begin SelectAll;Exit;End;
   3: Begin ClipCopy;Exit;End;
   24: Begin ClipCut;Exit;End;
   22: Begin ClipPaste;Exit;End;
   12: Begin SetAlign(AL_LEFT);Exit;End;
   18: Begin SetAlign(AL_RIGHT);Exit;End;
   5: Begin SetAlign(AL_CENTER);Exit;End;
   10: Begin SetAlign(AL_BOTH);Exit;End;
   K_ESC: Begin
     If (SelA>=0) Or MarkMode Then Begin SelA:=-1;MarkMode:=False;
       NeedDraw:=True;End
     Else SetPanel(MD_MAIN);
     Exit;
    End;
  End;
  TextKey(K);
  Exit;
 End;
 If K=K_ESC Then Begin
  If Mode=MD_ART Then Begin
   If ArtSub<>0 Then Begin ArtSub:=0;DrawStep:=0;NeedDraw:=True;End
   Else If HeldOn Then Begin HeldOn:=False;NeedDraw:=True;End
   Else SetPanel(MD_MAIN);
  End Else If Mode<>MD_MAIN Then SetPanel(MD_MAIN);
  Exit;
 End;
 Case Mode Of
  MD_ART: ArtKey(K);
  MD_LAYOUT: Case K Of
     K_PGUP,K_UP,K_LEFT: Begin If CurPage>1 Then Dec(CurPage);NeedDraw:=True;
       End;
     K_PGDN,K_DOWN,K_RIGHT: Begin If CurPage<NPg Then Inc(CurPage);
       NeedDraw:=True;End;
    End;
 Else ScrollKeys(K);
 End;
End;

{ ====================================================================== }
{                              SOURIS                                    }
{ ====================================================================== }

Function HitText(X,Y: LongInt): Boolean;
Var P,I,Best: Integer; LX_,LY_,D,BD: LongInt;
Begin
 HitText:=False;
 If Greek Then Exit;
 ScrToPage(X,Y-(MENU_H+1),P,LX_,LY_);
 Best:=-1;BD:=999999;
 For I:=0 To NLn-1 Do
  If Lines^[I].Pg=P Then Begin
   If LY_<Lines^[I].Y Then D:=Lines^[I].Y-LY_
   Else If LY_>=Lines^[I].Y+Lines^[I].H Then D:=LY_-(Lines^[I].Y+Lines^[I].H)+1
   Else D:=0;
   If D<BD Then Begin BD:=D;Best:=I;End;
  End;
 If Best<0 Then Exit;
 ASt:=Lines^[Best].Sty;
 Cur:=PosAtX(Best,Integer(LX_));
 If Cur>Lines^[Best].E Then Cur:=Lines^[Best].E;
 HitText:=True;
End;

Procedure MouseDown(X,Y: LongInt);
Var T,P: Integer; LX_,LY_: LongInt; OldSt,OldCur: Integer;
Begin
 If Y<MENU_H Then Begin
  T:=TitleHit(X,Y);
  If T>0 Then RunMenu(T,True);
  Exit;
 End;
 T:=PanelHit(X,Y);
 If (T>0) And ((Y>=PANEL_Y) Or (Mode=MD_LAYOUT)) Then Begin
  PBDown:=T;NeedDraw:=True;
  Exit;
 End;
 If (Mode=MD_LAYOUT) Or (Y>=PANEL_Y) Then Exit;
 Case Mode Of
  MD_TEXT: Begin
    OldSt:=ASt;OldCur:=Cur;
    If HitText(X,Y) Then Begin
     SelA:=-1;MarkMode:=False;WantX:=-1;
     Dragging:=1;
     Moved;
     If ASt<>OldSt Then TypRun:=False;
    End;
   End;
  MD_ART: Begin
    ScrToPage(X,Y-(MENU_H+1),P,LX_,LY_);
    ACx:=LX_;ACy:=LongInt(P-1)*(PGH+PGGAP)+LY_;
    If ACx<0 Then ACx:=0;
    If ACx>PGW-1 Then ACx:=PGW-1;
    If LY_<0 Then ACy:=LongInt(P-1)*(PGH+PGGAP);
    If LY_>=PGH Then ACy:=LongInt(P-1)*(PGH+PGGAP)+PGH-1;
    UpdateSelArt;
    If ArtSub=3 Then Begin ArtKey(K_ENTER);End
    Else If HeldOn Then StampHeld
    Else If SelArt>0 Then Begin
     Dragging:=2;
     DragOX:=ACx-Arts[SelArt].X;
     DragOY:=ACy-(LongInt(Arts[SelArt].Pg-1)*(PGH+PGGAP)+Arts[SelArt].Y);
    End;
    NeedDraw:=True;
   End;
 End;
End;

Procedure MouseMove(X,Y: LongInt);
Var P: Integer; LX_,LY_: LongInt; OldCur: Integer;
Begin
 If Dragging=0 Then Exit;
 Case Dragging Of
  1: Begin
      If Y<MENU_H+1 Then ScrollBy(0,-8) Else If Y>PANEL_Y-1 Then ScrollBy(0,8);
      OldCur:=Cur;
      If SelA<0 Then SelA:=Cur;
      If HitText(Max2(0,Min2(X,VW-1)),Max2(MENU_H+1,Min2(Y,PANEL_Y-1))) Then
        Begin
       If Cur<>OldCur Then Begin SyncFont;NeedDraw:=True;End;
      End;
     End;
  2: If SelArt>0 Then Begin
      ScrToPage(X,Y-(MENU_H+1),P,LX_,LY_);
      Arts[SelArt].Pg:=P;
      Arts[SelArt].X:=Integer(LX_-DragOX);
      Arts[SelArt].Y:=Integer(LY_-DragOY);
      ClampArt(Arts[SelArt]);
      ACx:=Arts[SelArt].X+DragOX;
      ACy:=LongInt(P-1)*(PGH+PGGAP)+Arts[SelArt].Y+DragOY;
      Modified:=True;NeedDraw:=True;
     End;
 End;
End;

Procedure MouseUp(X,Y: LongInt);
Var H: Integer;
Begin
 If PBDown>0 Then Begin
  H:=PanelHit(X,Y);
  If H=PBDown Then Begin PBDown:=0;PanelKey(H);End
  Else PBDown:=0;
  NeedDraw:=True;
  Exit;
 End;
 If Dragging=2 Then Relayout;
 If (Dragging=1) And (SelA=Cur) Then SelA:=-1;
 Dragging:=0;
 NeedDraw:=True;
End;

{ ====================================================================== }
{                  INITIALISATION ET BOUCLE PRINCIPALE                   }
{ ====================================================================== }

Procedure InitData;
Var P: Integer;
Begin
 FillChar(St,SizeOf(St),0);
 FillChar(Arts,SizeOf(Arts),0);
 GetMem(Lines,SizeOf(TLineArr));
 GetMem(ClipT,CLIPCAP+2);GetMem(ClipF,CLIPCAP+2);
 GetMem(UndoT,STCAP+2);GetMem(UndoF,STCAP+2);GetMem(UndoA,STCAP+2);
 StInit(0,STCAP,DefBody,AL_LEFT);
 For P:=1 To MAXPG Do StInit(P,HCAP,DefHead,AL_CENTER);
 NPg:=1;NArt:=0;ClipN:=0;UndoOK:=False;
 ZN:=1;ZD:=1;ViewNo:=2;ScrX:=0;ScrY:=0;
 GuidesOn:=False;
 Mode:=MD_MAIN;CurPage:=1;
 ASt:=0;Cur:=0;SelA:=-1;MarkMode:=False;CurFont:=DefBody;WantX:=-1;
   TypRun:=False;
 ACStep:=4;ACx:=100;ACy:=100;SelArt:=0;HeldOn:=False;ArtSub:=0;CropEnd:=0;
 DrawKind:=AR_BOX;DrawPat:=0;DrawTh:=2;DrawStep:=0;LastPiece:=1;
 Quit:=False;NeedDraw:=True;Dragging:=0;MenuOpen:=0;MenuHi:=0;
 MX:=0;MY:=0;MB:=0;LastB:=0;LastFill:=-1;
 CaretOn:=False;CaretT:=0;PBDown:=0;StatusMsg:='';StatusT:=0;
 FindStr:='';DocName:='';Named:=False;Modified:=False;
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
       If (StatusMsg<>'') And ((T<StatusT) Or (T-StatusT>=500)) Then Begin
        StatusMsg:='';NeedDraw:=True;
       End;
       If (Mode=MD_TEXT) And ((T<CaretT) Or (T-CaretT>=50)) Then Begin
        HideMouse;ToggleCaret;ShowMouse;CaretT:=T;
       End;
      End;
  End;
 Until Quit;
End;

Procedure ShowHelpLine;
Begin
 WriteLn('NEWS - ',
   Tr('Clone graphique du programme de publication de journaux News Master.'));
 WriteLn;
 WriteLn(Tr('Utilisation : NEWS [fichier.NWC] [/?]'));
 WriteLn;
 WriteLn('  ',Tr('fichier.NWC  Journal '#133' ouvrir.'));
 WriteLn('  ',Tr('/?           Affiche cette aide.'));
 WriteLn;
 WriteLn(Tr('Langue : fran'#135'ais par d'#130'faut. LANGUAGE=EN : anglais, '+
   'LANGUAGE=GR : allemand.'));
 WriteLn(Tr('Place NEWS.FLB dans le r'#130'pertoire courant pour utiliser les '+
   'polices originales.'));
End;

Var Dummy: Boolean;

Procedure DetectLanguage;
Var S: String;
Begin
 Lang:=0;
 S:=Upper(GetEnv('LANGUAGE'));
 If Copy(S,1,2)='EN' Then Lang:=1;
 If (Copy(S,1,2)='GR') Or (Copy(S,1,2)='DE') Then Lang:=2;
End;

BEGIN
 Dummy:=False;
 DetectLanguage;
 If (ParamCount>=1) And ((ParamStr(1)='/?') Or (ParamStr(1)='-h') Or
    (ParamStr(1)='--help')) Then Begin
  ShowHelpLine;
  Halt(0);
 End;
 InitializeGraphics;
 ReadBios8;
 BuildLibrary;
 FLBFound:=FindFLB;
 UseFLB:=FLBFound;
 BuildFontTable;
 InitData;
 {$IFDEF FPC}
 Dummy:=PtcMouse.InitMouse;
 {$ELSE}
 If MouseDriverFound Then ShowMouse;
 {$ENDIF}
 SetPanel(MD_MAIN);
 ShowSplash;
 If (ParamCount>=1) And FileExists(AddExt(ParamStr(1),'NWC')) And
   LoadNWC(AddExt(ParamStr(1),'NWC')) Then Begin
  DocName:=AddExt(ParamStr(1),'NWC');Named:=True;Modified:=False;
  CurFont:=St[0].F^[0];
  Relayout;
 End Else MakeDemo;
 SetView(2);
 MainMenuLoop;
 If Not Quit Then MainLoop;
 CloseGraph;
END.
