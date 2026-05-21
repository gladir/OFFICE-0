{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/office-0)
  @abstract(Target: Free Pascal 3.2
  @description: Clone de l'application Visio de Microsoft
}

{ TODO: Liste de 25 points pour un clone complet de Visio

  === MENUS ET INTERFACE ===
  1. [FAIT] Implementer le menu principal avec File, Edit, View, Insert, Format, Shape, Tools, Window, Help
  2. [FAIT] Ajouter le menu File avec New, Open, Close, Save, Save As, Export, Print, Print Preview, Exit
  3. [FAIT] Ajouter le menu Edit avec Undo, Redo, Cut, Copy, Paste, Delete, Select All, Find, Replace
  4. [FAIT] Ajouter le menu View avec Zoom In, Zoom Out, Fit Page, Grid, Rulers, Guides, Snap to Grid
  5. [FAIT] Ajouter le menu Insert avec Shape, Text Box, Image, Connector, Page, Layer
  6. [FAIT] Ajouter le menu Format avec Fill, Line, Text, Alignment, Arrange, Group, Ungroup
  7. [FAIT] Ajouter le menu Shape avec Rotate, Flip, Align, Distribute, Size, Position, Operations (Union, Intersect, Subtract)
  8. [FAIT] Implementer la barre d'outils avec boutons pour les actions frequentes (Selection, Rectangle, Ellipse, Ligne, Connecteur, Texte)

  === SUPPORT SOURIS ===
  9. [FAIT] Gerer les evenements de clic gauche pour selection et dessin d'objets
  10. [FAIT] Gerer le clic droit pour afficher un menu contextuel avec options (Cut, Copy, Paste, Delete, Properties)
  11. [FAIT] Implementer le glisser-deposer (drag and drop) pour deplacer et redimensionner les objets
  12. [FAIT] Ajouter les poignees de redimensionnement sur les objets selectionnes avec detection de survol

  === OBJETS ET FORMES ===
  13. [FAIT] Creer les types d'objets de base: Rectangle, Ellipse, Ligne, Polygone, Courbe de Bezier, Texte, Image
  14. [FAIT] Implementer les connecteurs entre objets avec points d'ancrage automatiques
  15. [FAIT] Permettre la modification des proprietes des objets: couleur de remplissage, couleur de trait, epaisseur de ligne, style de ligne
  16. [FAIT] Ajouter le support des calques (layers) avec visibilite et verrouillage
  17. [FAIT] Implementer la gestion des groupes d'objets (grouper, degrouper, entrer dans le groupe)

  === FORMAT DE FICHIER VISIO ===
  18. [FAIT] Parser et lire les fichiers Visio VSD/VSDX (format binaire OLE et format XML compresse)
  19. [FAIT] Ecrire et sauvegarder les fichiers au format Visio VSD/VSDX
  20. [FAIT] Gerer les stencils et les masters Visio

  === FORMAT SVG ===
  21. [FAIT] Parser et importer les fichiers SVG avec support des elements path, rect, circle, ellipse, line, polygon, text
  22. [FAIT] Exporter les dessins au format SVG avec attributs de style CSS

  === EXPORT IMAGES ===
  23. [FAIT] Exporter en format BMP avec support 1-bit, 4-bit, 8-bit, 24-bit
  24. [FAIT] Exporter en format GIF avec palette de 256 couleurs et transparence
  25. [FAIT] Exporter en format JPEG avec compression reglable et en format PNG avec canal alpha pour transparence
}

Program VISIO;

{$IFDEF FPC}
 {$R-}
{$ENDIF}

Uses {$IFDEF FPC}
      Crt,PtcGraph,PtcCrt,PtcMouse,Dos
     {$ELSE}
      Crt,Graph,Dos
     {$ENDIF};

Const
 { Constantes pour le menu principal }
 MENU_COUNT = 9;
 MENU_HEIGHT = 18;
 MENU_BAR_COLOR = 7;      { Gris clair }
 MENU_TEXT_COLOR = 0;     { Noir }
 MENU_HIGHLIGHT_BG = 1;   { Bleu }
 MENU_HIGHLIGHT_FG = 15;  { Blanc }

 { Constantes pour la barre d'outils (verticale, a gauche) }
 TOOLBAR_COUNT = 9;
 TOOLBAR_TOP = 43;        { Juste en dessous de la barre d'icones }
 TOOLBAR_WIDTH = 28;      { Largeur de la barre d'outils verticale }
 TOOLBAR_HEIGHT = 26;     { Conserve pour compatibilite (hauteur d'un bouton) }
 TOOLBAR_BUTTON_SIZE = 24; { Taille d'un bouton }
 TOOLBAR_PADDING = 2;     { Espacement entre les boutons }
 TOOLBAR_COLOR = 7;       { Gris clair - mÃªme couleur que la barre de menu }
 TOOLBAR_BTN_COLOR = 15;  { Blanc - fond des boutons }
 TOOLBAR_BTN_BORDER = 8;  { Gris foncÃ© - bordure des boutons }
 TOOLBAR_BTN_SELECTED = 1; { Bleu - bouton sÃ©lectionnÃ© }

 { Constantes pour la barre d'icones horizontale (sous le menu) }
 ICONBAR_TOP = 19;        { Juste en dessous de la barre de menu }
 ICONBAR_HEIGHT = 24;     { Hauteur de la barre d'icones }
 ICONBAR_BUTTON_SIZE = 20; { Taille d'un bouton }
 ICONBAR_PADDING = 2;
 ICONBAR_COUNT = 8;       { 6 icones + 2 separateurs }
 ICONBAR_COLOR = 7;       { Gris clair }

 { Constantes pour la zone de travail et les objets }
 WORK_AREA_TOP = 43;      { DÃ©but de la zone de travail (sous barre d'icones) }
 MAX_SHAPES = 100;        { Nombre maximum d'objets }
 DEFAULT_SHAPE_WIDTH = 80;  { Largeur par dÃ©faut d'une forme }
 DEFAULT_SHAPE_HEIGHT = 60; { Hauteur par dÃ©faut d'une forme }
 SELECTION_HANDLE_SIZE = 6; { Taille des poignÃ©es de sÃ©lection }

 { Constantes pour les polygones et courbes de BÃ©zier }
 MAX_POLYGON_POINTS = 20;  { Nombre maximum de points pour un polygone }
 MAX_BEZIER_POINTS = 4;    { Nombre de points de contrÃ´le pour une courbe de BÃ©zier cubique }

 { Couleurs pour les poignÃ©es de redimensionnement }
 HANDLE_NORMAL_COLOR = 1;   { Bleu - couleur normale des poignÃ©es }
 HANDLE_HOVER_COLOR = 4;    { Rouge - couleur des poignÃ©es survolÃ©es }
 HANDLE_BORDER_COLOR = 15;  { Blanc - bordure des poignÃ©es }

 { Constantes pour le menu contextuel (clic droit) }
 CONTEXT_MENU_ITEM_COUNT = 5;     { Nombre d'Ã©lÃ©ments : Cut, Copy, Paste, Delete, Properties }
 CONTEXT_MENU_WIDTH = 100;        { Largeur du menu contextuel }
 CONTEXT_MENU_ITEM_HEIGHT = 18;   { Hauteur d'un Ã©lÃ©ment }
 CONTEXT_MENU_BG_COLOR = 15;      { Blanc - fond du menu }
 CONTEXT_MENU_BORDER_COLOR = 8;   { Gris foncÃ© - bordure }
 CONTEXT_MENU_TEXT_COLOR = 0;     { Noir - texte }
 CONTEXT_MENU_HIGHLIGHT_BG = 1;   { Bleu - surbrillance }
 CONTEXT_MENU_HIGHLIGHT_FG = 15;  { Blanc - texte surbrillance }
 CONTEXT_MENU_DISABLED_COLOR = 8; { Gris - texte dÃ©sactivÃ© }

 { Constantes pour le glisser-dÃ©poser (drag and drop) }
 DRAG_MODE_NONE = 0;      { Pas de glissement en cours }
 DRAG_MODE_MOVE = 1;      { DÃ©placement d'un objet }
 DRAG_MODE_RESIZE = 2;    { Redimensionnement d'un objet }

 { Constantes pour les poignÃ©es de redimensionnement }
 RESIZE_HANDLE_SIZE = 6;   { Taille des poignÃ©es en pixels }

 { Constantes pour les points d'ancrage des connecteurs }
 ANCHOR_NONE = 0;         { Pas d'ancrage }
 ANCHOR_TOP = 1;          { Point d'ancrage en haut (centre) }
 ANCHOR_BOTTOM = 2;       { Point d'ancrage en bas (centre) }
 ANCHOR_LEFT = 3;         { Point d'ancrage Ã  gauche (centre) }
 ANCHOR_RIGHT = 4;        { Point d'ancrage Ã  droite (centre) }
 ANCHOR_CENTER = 5;       { Point d'ancrage au centre }
 ANCHOR_COUNT = 4;        { Nombre de points d'ancrage par forme (haut, bas, gauche, droite) }
 ANCHOR_POINT_SIZE = 5;   { Taille des points d'ancrage en pixels }
 ANCHOR_SNAP_DISTANCE = 15; { Distance max pour accrocher Ã  un point d'ancrage }
 RESIZE_HANDLE_NONE = 0;   { Aucune poignÃ©e }
 RESIZE_HANDLE_NW = 1;     { Coin nord-ouest (haut-gauche) }
 RESIZE_HANDLE_N = 2;      { Milieu nord (haut) }
 RESIZE_HANDLE_NE = 3;     { Coin nord-est (haut-droite) }
 RESIZE_HANDLE_E = 4;      { Milieu est (droite) }
 RESIZE_HANDLE_SE = 5;     { Coin sud-est (bas-droite) }
 RESIZE_HANDLE_S = 6;      { Milieu sud (bas) }
 RESIZE_HANDLE_SW = 7;     { Coin sud-ouest (bas-gauche) }
 RESIZE_HANDLE_W = 8;      { Milieu ouest (gauche) }

 { Constantes pour les styles de ligne }
 LINESTYLE_SOLID = 0;      { Ligne continue }
 LINESTYLE_DASHED = 1;     { Ligne tiretÃ©e }
 LINESTYLE_DOTTED = 2;     { Ligne pointillÃ©e }
 LINESTYLE_DASHDOT = 3;    { Ligne tiret-point }
 LINESTYLE_COUNT = 4;      { Nombre de styles de ligne }

 { Constantes pour la boÃ®te de dialogue des propriÃ©tÃ©s }
 PROP_DIALOG_WIDTH = 250;   { Largeur de la boÃ®te de dialogue }
 PROP_DIALOG_HEIGHT = 200;  { Hauteur de la boÃ®te de dialogue }
 PROP_DIALOG_BG = 7;        { Gris clair - fond }
 PROP_DIALOG_BORDER = 8;    { Gris foncÃ© - bordure }
 PROP_DIALOG_TEXT = 0;      { Noir - texte }
 PROP_DIALOG_BTN_BG = 15;   { Blanc - fond des boutons }
 PROP_DIALOG_BTN_HL = 1;    { Bleu - bouton surlignÃ© }
 PROP_COLOR_BOX_SIZE = 16;  { Taille des cases de couleur }
 PROP_MAX_COLORS = 16;      { Nombre de couleurs dans la palette }

 { Constantes pour la boÃ®te de dialogue des calques }
 LAYER_DIALOG_WIDTH = 280;    { Largeur de la boÃ®te de dialogue des calques }
 LAYER_DIALOG_HEIGHT = 250;   { Hauteur de la boÃ®te de dialogue des calques }
 LAYER_ITEM_HEIGHT = 20;      { Hauteur d'un Ã©lÃ©ment de calque }
 LAYER_NAME_LENGTH = 30;      { Longueur max du nom de calque }

 { Constantes pour le parsing des fichiers Visio VSD/VSDX }
 VISIO_FORMAT_UNKNOWN = 0;    { Format inconnu }
 VISIO_FORMAT_VSD = 1;        { Format VSD (OLE binaire) }
 VISIO_FORMAT_VSDX = 2;       { Format VSDX (XML compressÃ© ZIP) }

 { Taille des signatures de fichier }
 VSD_SIG_SIZE = 8;
 VSDX_SIG_SIZE = 4;

 { Constantes pour les structures OLE }
 OLE_SECTOR_SIZE = 512;       { Taille d'un secteur OLE }
 OLE_MINI_SECTOR_SIZE = 64;   { Taille d'un mini-secteur }
 OLE_ENDOFCHAIN = $FFFFFFFE;  { Marqueur de fin de chaÃ®ne }
 OLE_FREESECT = $FFFFFFFF;    { Secteur libre }

 { Types de formes Visio }
 VISIO_SHAPE_RECTANGLE = 1;
 VISIO_SHAPE_ELLIPSE = 2;
 VISIO_SHAPE_LINE = 3;
 VISIO_SHAPE_POLYLINE = 4;
 VISIO_SHAPE_CONNECTOR = 5;
 VISIO_SHAPE_TEXT = 6;
 VISIO_SHAPE_GROUP = 7;

 { Constantes pour les Stencils et Masters Visio }
 MAX_MASTERS = 100;                    { Nombre maximum de masters par stencil }
 MAX_STENCILS = 20;                    { Nombre maximum de stencils chargÃ©s }
 MAX_MASTER_NAME_LENGTH = 50;          { Longueur max du nom d'un master }
 MAX_STENCIL_NAME_LENGTH = 100;        { Longueur max du nom d'un stencil }
 VISIO_STENCIL_FORMAT_VSS = 1;         { Format VSS (OLE binaire) }
 VISIO_STENCIL_FORMAT_VSSX = 2;        { Format VSSX (XML compressÃ© ZIP) }

 { Constantes pour les calques (utilisÃ©es dans la dÃ©claration de Layers) }
 MAX_LAYERS = 50;
 MAX_PAGES = 100;
 DEFAULT_PAGE_COUNT = 1;
 DEFAULT_LAYER_COUNT = 1;

 { Noms des Ã©lÃ©ments du menu contextuel }
 ContextMenuNames: Array[1..CONTEXT_MENU_ITEM_COUNT] of String[12] = (
   'Cut', 'Copy', 'Paste', 'Delete', 'Properties'
 );

 { Noms des outils de la barre d'outils }
 ToolNames: Array[1..TOOLBAR_COUNT] of String[12] = (
   'Selection', 'Rectangle', 'Ellipse', 'Line', 'Connector', 'Text', 'Polygon', 'Bezier', 'Image'
 );

 { Noms des menus principaux }
 MenuNames: Array[1..MENU_COUNT] of String[10] = (
   'File', 'Edit', 'View', 'Insert', 'Format', 'Shape', 'Tools', 'Window', 'Help'
 );

 { Positions X des menus }
 MenuPositions: Array[1..MENU_COUNT] of Integer = (
   5, 50, 95, 140, 195, 260, 320, 375, 440
 );

Type
 TMenuState = (msNone, msMenuBar, msDropDown);
 TToolType = (ttSelection, ttRectangle, ttEllipse, ttLine, ttConnector, ttText, ttPolygon, ttBezier, ttImage);
 TShapeType = (stNone, stRectangle, stEllipse, stLine, stConnector, stText, stPolygon, stBezier, stImage);

 { Structure pour l'en-tÃªte OLE Compound Document (format VSD) }
 TOLEHeader = Record
  Signature: Array[0..7] of Byte;      { Signature du fichier OLE }
  CLSID: Array[0..15] of Byte;         { CLSID }
  MinorVersion: Word;                   { Version mineure }
  MajorVersion: Word;                   { Version majeure }
  ByteOrder: Word;                      { Ordre des octets (0xFFFE = little-endian) }
  SectorShift: Word;                    { Puissance de 2 pour la taille du secteur }
  MiniSectorShift: Word;                { Puissance de 2 pour la taille du mini-secteur }
  Reserved: Array[0..5] of Byte;        { RÃ©servÃ© }
  TotalSectors: LongInt;                { Nombre total de secteurs }
  FirstDirSector: LongInt;              { Premier secteur du rÃ©pertoire }
  TransactionSig: LongInt;              { Signature de transaction }
  MiniStreamCutoff: LongInt;            { Taille limite pour mini-stream (4096) }
  FirstMiniFATSector: LongInt;          { Premier secteur du mini-FAT }
  NumMiniFATSectors: LongInt;           { Nombre de secteurs mini-FAT }
  FirstDIFATSector: LongInt;            { Premier secteur DIFAT }
  NumDIFATSectors: LongInt;             { Nombre de secteurs DIFAT }
  DIFAT: Array[0..108] of LongInt;      { Table DIFAT initiale }
 End;

 { Structure pour une entrÃ©e du rÃ©pertoire OLE }
 TOLEDirectoryEntry = Record
  EntryName: Array[0..63] of Byte;     { Nom de l'entrÃ©e (UTF-16) }
  NameLength: Word;                     { Longueur du nom en octets }
  ObjectType: Byte;                     { Type: 0=inconnu, 1=storage, 2=stream, 5=root }
  ColorFlag: Byte;                      { Couleur dans l'arbre rouge-noir }
  LeftSiblingID: LongInt;               { ID du frÃ¨re gauche }
  RightSiblingID: LongInt;              { ID du frÃ¨re droit }
  ChildID: LongInt;                     { ID de l'enfant }
  CLSID: Array[0..15] of Byte;          { CLSID }
  StateBits: LongInt;                   { Bits d'Ã©tat }
  CreationTime: Array[0..7] of Byte;    { Date de crÃ©ation }
  ModifiedTime: Array[0..7] of Byte;    { Date de modification }
  StartSector: LongInt;                 { Premier secteur du stream }
  StreamSize: Array[0..7] of Byte;      { Taille du stream }
 End;

 { Structure pour une forme Visio importÃ©e }
 TVisioShape = Record
  ID: LongInt;                          { ID unique de la forme }
  ShapeType: Integer;                   { Type de forme Visio }
  X, Y: Real;                           { Position }
  Width, Height: Real;                  { Dimensions }
  Angle: Real;                          { Angle de rotation }
  FillColor: LongInt;                   { Couleur de remplissage }
  LineColor: LongInt;                   { Couleur de ligne }
  LineWeight: Real;                     { Ã‰paisseur de ligne }
  Text: String[255];                    { Texte de la forme }
  ParentID: LongInt;                    { ID du parent (pour les groupes) }
 End;

 { Structure pour un Master Visio (forme modÃ¨le rÃ©utilisable) }
 TVisioMaster = Record
  ID: LongInt;                                   { ID unique du master }
  Name: String[MAX_MASTER_NAME_LENGTH];          { Nom du master }
  UniqueID: String[40];                          { ID unique universel (GUID) }
  IconIndex: Integer;                            { Index de l'icÃ´ne }
  BaseShape: TVisioShape;                        { Forme de base du master }
  Width, Height: Real;                           { Dimensions par dÃ©faut }
  OffsetX, OffsetY: Real;                        { DÃ©calage du point d'ancrage }
  IsGroup: Boolean;                              { True si le master est un groupe }
  SubShapeCount: Integer;                        { Nombre de sous-formes }
  SubShapes: Array[1..20] of TVisioShape;        { Sous-formes (si groupe) }
  ConnectionPointCount: Integer;                 { Nombre de points de connexion }
  ConnectionPoints: Array[1..8] of Record        { Points de connexion }
   X, Y: Real;                                   { Position relative }
   DirX, DirY: Real;                             { Direction de la connexion }
  End;
 End;

 { Structure pour un Stencil Visio (collection de masters) }
 TVisioStencil = Record
  Name: String[MAX_STENCIL_NAME_LENGTH];         { Nom du stencil }
  FilePath: String[255];                         { Chemin du fichier }
  FileFormat: Integer;                           { Format (VSS ou VSSX) }
  MasterCount: Integer;                          { Nombre de masters }
  Masters: Array[1..MAX_MASTERS] of TVisioMaster; { Masters du stencil }
  IsModified: Boolean;                           { True si le stencil a Ã©tÃ© modifiÃ© }
  IsReadOnly: Boolean;                           { True si le stencil est en lecture seule }
 End;

 { Structure pour un calque }
 TLayer = Record
  Name: String[LAYER_NAME_LENGTH]; { Nom du calque }
  Visible: Boolean;                { Calque visible }
  Locked: Boolean;                 { Calque verrouillÃ© (pas modifiable) }
  Color: Integer;                  { Couleur d'identification du calque }
 End;

 { Structure pour stocker les points d'un polygone ou d'une courbe de BÃ©zier }
 TPointArray = Array[1..MAX_POLYGON_POINTS] of Record
  X, Y: Integer;
 End;

 { Structure pour un objet graphique }
 TShapeObject = Record
  ShapeType: TShapeType;
  X1, Y1, X2, Y2: Integer;  { CoordonnÃ©es du rectangle englobant }
  FillColor: Integer;        { Couleur de remplissage }
  LineColor: Integer;        { Couleur de contour }
  LineWidth: Integer;        { Ã‰paisseur de ligne }
  LineStyle: Integer;        { Style de ligne (LINESTYLE_*) }
  LayerIndex: Integer;       { Index du calque auquel appartient l'objet }
  GroupID: Integer;          { ID du groupe (0 = pas dans un groupe) }
  Text: String[80];          { Texte (pour objets texte) }
  Selected: Boolean;         { Objet sÃ©lectionnÃ© }
  { Champs pour les polygones et courbes de BÃ©zier }
  Points: TPointArray;       { Points du polygone ou de la courbe de BÃ©zier }
  PointCount: Integer;       { Nombre de points utilisÃ©s }
  { Champ pour les images }
  ImagePath: String[255];    { Chemin vers le fichier image }
  { Champs pour les connecteurs avec points d'ancrage automatiques }
  ConnectStartShape: Integer;  { Index de la forme source (0 = pas connectÃ©) }
  ConnectEndShape: Integer;    { Index de la forme cible (0 = pas connectÃ©) }
  ConnectStartAnchor: Integer; { Point d'ancrage source (ANCHOR_*) }
  ConnectEndAnchor: Integer;   { Point d'ancrage cible (ANCHOR_*) }
 End;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain,_Albanian,_Portuguese,_Swedish,_Danish,_Japanese);
 TmpLanguage:String;

 CurrentMenu: Integer;
 MenuState: TMenuState;
 ScreenWidth, ScreenHeight: Integer;
 CurrentTool: TToolType;
 { Message d'etat (affiche en bas de l'ecran apres une action) }
 StatusMessage: String[80];
 { Variables pour les objets graphiques }
 Shapes: Array[1..MAX_SHAPES] of TShapeObject;
 ShapeCount: Integer;
 SelectedShape: Integer;
 { Variables pour les calques }
 Layers: Array[1..MAX_LAYERS] of TLayer;
 { Variables pour le dessin Ã  la souris }
 IsDrawing: Boolean;
 DrawStartX, DrawStartY: Integer;
 LastMouseX, LastMouseY: Integer;
 LastMouseButton: LongInt;
 { Apercu XOR (rubber-band) pendant le dessin d'une forme }
 PreviewValid: Boolean;
 PreviewTool: TToolType;
 PreviewX1, PreviewY1, PreviewX2, PreviewY2: Integer;
 PreviewBlinkTick: Word;
 PreviewVisible: Boolean;
 { Variables pour le menu contextuel (clic droit) }
 ContextMenuVisible: Boolean;
 ContextMenuX, ContextMenuY: Integer;
 ContextMenuHighlight: Integer;
 { Variables pour le glisser-dÃ©poser (drag and drop) }
 DragMode: Integer;           { Mode de glissement actuel (DRAG_MODE_*) }
 DragStartX, DragStartY: Integer;  { Position de dÃ©part du glissement }
 DragOffsetX, DragOffsetY: Integer; { DÃ©calage entre clic et coin de l'objet }
 DragResizeHandle: Integer;   { PoignÃ©e de redimensionnement en cours }
 DragOrigX1, DragOrigY1: Integer;  { CoordonnÃ©es originales de l'objet }
 DragOrigX2, DragOrigY2: Integer;
 { Variable pour le survol des poignÃ©es }
 HoveredHandle: Integer;      { PoignÃ©e actuellement survolÃ©e (RESIZE_HANDLE_*) }
 OldHoveredHandle: Integer;   { Ancienne poignÃ©e survolÃ©e (pour dÃ©tection de changement) }
 { Variables pour le survol clavier/souris des items de menu deroulant }
 HoveredMenuItem: Integer;    { Item de menu actuellement survole (0=aucun) }
 OldHoveredMenuItem: Integer; { Pour detection de changement }
 PrevMouseX, PrevMouseY: Integer; { Position precedente de la souris (detection de mouvement) }
 HoveredMenuOnBar: Integer;   { Menu de la barre survole quand un deroulant est ouvert }
 { Variables temporaires de la boucle principale (clavier) }
 MainLoopKey: Char;
 MainLoopExit: Boolean;
 { Variables pour les connecteurs et points d'ancrage }
 HoveredShapeForAnchor: Integer;  { Forme survolÃ©e pour afficher les points d'ancrage }
 NearestAnchorPoint: Integer;     { Point d'ancrage le plus proche de la souris }
 { Variables pour la boÃ®te de dialogue des calques }
 LayerDialogVisible: Boolean;
 LayerDialogX, LayerDialogY: Integer;
 LayerDialogSelectedLayer: Integer;
 LayerDialogHighlightedButton: Integer;
 { Variables pour les Stencils et Masters Visio }
 Stencils: Array[1..MAX_STENCILS] of TVisioStencil;
 StencilCount: Integer;
 CurrentStencil: Integer;        { Stencil actuellement sÃ©lectionnÃ© }
 NextMasterID: LongInt;          { Prochain ID de master disponible }

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
  { Pas d'implÃ©mentation pour Free Pascal }
 End;

 Procedure HideMouse;
 Begin
  { Pas d'implÃ©mentation pour Free Pascal }
 End;
{$ENDIF}

{ ============================================================================ }
{ === PROCEDURES DU MENU FILE === }
{ ============================================================================ }

Var
 CurrentFileName: String;
 DocumentModified: Boolean;

{ ============================================================================ }
{ === FONCTIONS DE PARSING DES FICHIERS VISIO VSD/VSDX === }
{ ============================================================================ }

{ Fonction pour dÃ©tecter le format d'un fichier Visio }
Function DetectVisioFormat(Const FileName: String): Integer;
Var
 F: File;
 Buffer: Array[0..7] of Byte;
 BytesRead: Integer;
Begin
 DetectVisioFormat := VISIO_FORMAT_UNKNOWN;

 Assign(F, FileName);
 {$I-}
 Reset(F, 1);
 {$I+}
 If IOResult <> 0 Then Exit;

 { Lire les premiers octets pour identifier le format }
 BlockRead(F, Buffer, 8, BytesRead);
 Close(F);

 If BytesRead < 4 Then Exit;

 { VÃ©rifier si c'est un fichier VSDX (ZIP) }
 If (Buffer[0] = $50) and (Buffer[1] = $4B) and
    (Buffer[2] = $03) and (Buffer[3] = $04) Then Begin
  DetectVisioFormat := VISIO_FORMAT_VSDX;
  Exit;
 End;

 { VÃ©rifier si c'est un fichier VSD (OLE Compound Document) }
 If BytesRead >= 8 Then Begin
  If (Buffer[0] = $D0) and (Buffer[1] = $CF) and
     (Buffer[2] = $11) and (Buffer[3] = $E0) and
     (Buffer[4] = $A1) and (Buffer[5] = $B6) and
     (Buffer[6] = $1A) and (Buffer[7] = $E1) Then Begin
   DetectVisioFormat := VISIO_FORMAT_VSD;
   Exit;
  End;
 End;
End;

{ Fonction pour lire l'en-tÃªte OLE d'un fichier VSD }
Function ReadOLEHeader(Var F: File; Var Header: TOLEHeader): Boolean;
Var
 BytesRead: Integer;
Begin
 ReadOLEHeader := False;

 { Positionner au dÃ©but du fichier }
 Seek(F, 0);

 { Lire l'en-tÃªte complet (512 octets) }
 BlockRead(F, Header, SizeOf(TOLEHeader), BytesRead);

 If BytesRead < SizeOf(TOLEHeader) Then Exit;

 { VÃ©rifier la signature OLE }
 If (Header.Signature[0] <> $D0) or (Header.Signature[1] <> $CF) or
    (Header.Signature[2] <> $11) or (Header.Signature[3] <> $E0) Then Exit;

 ReadOLEHeader := True;
End;

{ Fonction pour lire une entrÃ©e du rÃ©pertoire OLE }
Function ReadOLEDirectoryEntry(Var F: File; SectorNum: LongInt; EntryIndex: Integer;
                                SectorSize: Integer; Var Entry: TOLEDirectoryEntry): Boolean;
Var
 Offset: LongInt;
 BytesRead: Integer;
Begin
 ReadOLEDirectoryEntry := False;

 { Calculer l'offset dans le fichier }
 { Les secteurs commencent aprÃ¨s l'en-tÃªte (512 octets) }
 Offset := (SectorNum + 1) * SectorSize + (EntryIndex * 128);

 { Positionner et lire l'entrÃ©e }
 {$I-}
 Seek(F, Offset);
 {$I+}
 If IOResult <> 0 Then Exit;

 BlockRead(F, Entry, SizeOf(TOLEDirectoryEntry), BytesRead);

 If BytesRead >= 128 Then
  ReadOLEDirectoryEntry := True;
End;

{ Fonction pour extraire le nom d'une entrÃ©e OLE (UTF-16 vers ASCII) }
Function GetOLEEntryName(Const Entry: TOLEDirectoryEntry): String;
Var
 I: Integer;
 S: String;
 NameLen: Integer;
Begin
 S := '';
 NameLen := Entry.NameLength div 2 - 1; { UTF-16, moins le null terminator }
 If NameLen > 31 Then NameLen := 31;
 If NameLen < 0 Then NameLen := 0;

 For I := 0 to NameLen - 1 do Begin
  { Prendre le premier octet de chaque caractÃ¨re UTF-16 (ASCII seulement) }
  If Entry.EntryName[I * 2] > 0 Then
   S := S + Chr(Entry.EntryName[I * 2]);
 End;

 GetOLEEntryName := S;
End;

{ Fonction pour convertir une couleur Visio en couleur Pascal }
Function VisioColorToPascalColor(VisioColor: LongInt): Integer;
Var
 R, G, B: Byte;
Begin
 { Les couleurs Visio sont en format BGR }
 B := (VisioColor shr 16) and $FF;
 G := (VisioColor shr 8) and $FF;
 R := VisioColor and $FF;

 { Mapper vers les 16 couleurs de base }
 If (R < 64) and (G < 64) and (B < 64) Then
  VisioColorToPascalColor := 0  { Noir }
 Else If (R > 192) and (G > 192) and (B > 192) Then
  VisioColorToPascalColor := 15 { Blanc }
 Else If (R > 192) and (G < 64) and (B < 64) Then
  VisioColorToPascalColor := 4  { Rouge }
 Else If (R < 64) and (G > 192) and (B < 64) Then
  VisioColorToPascalColor := 2  { Vert }
 Else If (R < 64) and (G < 64) and (B > 192) Then
  VisioColorToPascalColor := 1  { Bleu }
 Else If (R > 192) and (G > 192) and (B < 64) Then
  VisioColorToPascalColor := 14 { Jaune }
 Else If (R > 192) and (G < 64) and (B > 192) Then
  VisioColorToPascalColor := 5  { Magenta }
 Else If (R < 64) and (G > 192) and (B > 192) Then
  VisioColorToPascalColor := 3  { Cyan }
 Else
  VisioColorToPascalColor := 7; { Gris }
End;

{ Fonction pour convertir un type de forme Visio en TShapeType }
Function VisioShapeTypeToTShapeType(VisioType: Integer): TShapeType;
Begin
 Case VisioType of
  VISIO_SHAPE_RECTANGLE: VisioShapeTypeToTShapeType := stRectangle;
  VISIO_SHAPE_ELLIPSE: VisioShapeTypeToTShapeType := stEllipse;
  VISIO_SHAPE_LINE: VisioShapeTypeToTShapeType := stLine;
  VISIO_SHAPE_POLYLINE: VisioShapeTypeToTShapeType := stPolygon;
  VISIO_SHAPE_CONNECTOR: VisioShapeTypeToTShapeType := stConnector;
  VISIO_SHAPE_TEXT: VisioShapeTypeToTShapeType := stText;
 Else
  VisioShapeTypeToTShapeType := stRectangle; { Par dÃ©faut }
 End;
End;

{ Fonction pour convertir une TVisioShape en TShapeObject }
Procedure VisioShapeToShapeObject(Const VSh: TVisioShape; Var Shape: TShapeObject);
Begin
 Shape.ShapeType := VisioShapeTypeToTShapeType(VSh.ShapeType);
 Shape.X1 := Round(VSh.X);
 Shape.Y1 := Round(VSh.Y);
 Shape.X2 := Round(VSh.X + VSh.Width);
 Shape.Y2 := Round(VSh.Y + VSh.Height);
 Shape.FillColor := VisioColorToPascalColor(VSh.FillColor);
 Shape.LineColor := VisioColorToPascalColor(VSh.LineColor);
 Shape.LineWidth := Round(VSh.LineWeight);
 If Shape.LineWidth < 1 Then Shape.LineWidth := 1;
 Shape.LineStyle := LINESTYLE_SOLID;
 Shape.LayerIndex := 1;
 Shape.GroupID := 0;
 If VSh.ParentID > 0 Then
  Shape.GroupID := VSh.ParentID;
 Shape.Text := VSh.Text;
 Shape.Selected := False;
 Shape.PointCount := 0;
 Shape.ImagePath := '';
 Shape.ConnectStartShape := 0;
 Shape.ConnectEndShape := 0;
 Shape.ConnectStartAnchor := ANCHOR_NONE;
 Shape.ConnectEndAnchor := ANCHOR_NONE;
End;

{ ============================================================================ }
{ === PARSEUR VSDX REEL : extraction ZIP built-in (CORAIL UNZIP) + parsing XML }
{ ============================================================================ }
{ Strategie: VSDX = ZIP de fichiers XML. On utilise le decompresseur ZIP       }
{ embarque depuis le projet Corail. 100% Pascal, aucun outil    }
{ externe. On extrait dans un repertoire temp, puis on parse                   }
{ visio\pages\page1.xml a la recherche de <Shape> elements avec leurs          }
{ cellules PinX/PinY/Width/Height et leur <Text>...</Text>.                    }

{ === Begin CORAIL UNZIP include — Program/Uses/Memory directives stripped === }

{$PUSH}
{$Q-}
{$R-}

Const
 MaxBits=16;
 MaxSymbols=320;
 WindowHalfSize=32768;
 MaxExclude=20;
 ShrinkMaxCode=8191;
 DLEByte=144;
 BZMaxAlphaSize=258;
 BZMaxGroups=6;
 BZGroupSize=50;
 BZMaxSelectors=18002;
 BZChunkSize=16000;
 BZMaxChunks=57;
 LZNumStates=12;
 LZNumPosBitsMax=4;
 LZNumPosStatesMax=16;
 LZNumLenToPosStates=4;
 LZNumAlignBits=4;
 LZAlignTableSize=16;
 LZStartPosModelIndex=4;
 LZEndPosModelIndex=14;
 LZNumFullDistances=128;
 LZLenLowSymbols=8;
 LZLenMidSymbols=8;
 LZLenHighSymbols=256;
 LZLitContextSize=768;
 LZMaxLitContexts=16;
 LZChunkSize=16384;
 LZMaxChunks=256;
 LZBitModelTotal=2048;
 LZMoveBits=5;
 TerseTreeSize=4096;
 TerseCodeSize=257;
 TerseRecordMark=257;
 TerseEOF=0;
 TerseNone=-1;
 TerseStackSize=2047;
 DCLMaxBits=13;
 DCLWindowSize=4096;
 ZstdFSEMaxTableLog=12;
 ZstdFSEMaxTableSize=4096;
 ZstdFSEMaxSymbols=256;
 ZstdHuffMaxSymbols=256;
 ZstdHuffMaxBits=12;
 ZstdHuffMaxTableSize=4096;
 ZstdSeqMaxBlockSize=131072;
 ZstdSeqChunkBits=14;
 ZstdSeqChunkSize=16384;        { 1 shl ZstdSeqChunkBits, < 64 Ko pour TP7 }
 ZstdSeqChunkMask=16383;        { ZstdSeqChunkSize-1 }
 ZstdSeqNumChunks=8;            { ZstdSeqMaxBlockSize div ZstdSeqChunkSize }

Type
 PWindowHalf=^TWindowHalf;
 TWindowHalf=Array[0..WindowHalfSize-1]of Byte;
 Huffman=Record
  NumSymbols:Integer;
  Len:Array[0..MaxSymbols-1]of Byte;
  Code:Array[0..MaxSymbols-1]of LongInt;
 End;
 PShrinkIntArray=^TShrinkIntArray;
 TShrinkIntArray=Array[0..ShrinkMaxCode]of Integer;
 PShrinkByteArray=^TShrinkByteArray;
 TShrinkByteArray=Array[0..ShrinkMaxCode]of Byte;
 PShrinkBoolArray=^TShrinkBoolArray;
 TShrinkBoolArray=Array[0..ShrinkMaxCode]of Boolean;
 PFollowerSizeArray=^TFollowerSizeArray;
 TFollowerSizeArray=Array[0..255]of Byte;
 PFollowerArray=^TFollowerArray;
 TFollowerArray=Array[0..255,0..31]of Byte;
 PBZTTChunk=^TBZTTChunk;
 TBZTTChunk=Array[0..BZChunkSize-1]of LongInt;
 PBZByteChunk=^TBZByteChunk;
 TBZByteChunk=Array[0..BZChunkSize-1]of Byte;
 PLZByteChunk=^TLZByteChunk;
 TLZByteChunk=Array[0..LZChunkSize-1]of Byte;
 PLZLitContext=^TLZLitContext;
 TLZLitContext=Array[0..LZLitContextSize-1]of Word;
 PWordArray=^TWordArray;
 TWordArray=Array[0..32759]of Word;
 PTerseIntArray=^TTerseIntArray;
 TTerseIntArray=Array[0..TerseTreeSize]of Integer;
 TTerseTreeRecord=Record
  Left,Right,Back,NextCount:Integer;
 End;
 PTerseTreeArray=^TTerseTreeArray;
 TTerseTreeArray=Array[0..TerseTreeSize]of TTerseTreeRecord;
 PTerseStackArray=^TTerseStackArray;
 TTerseStackArray=Array[0..TerseStackSize]of Integer;
 PDCLWindow=^TDCLWindow;
 TDCLWindow=Array[0..DCLWindowSize-1]of Byte;
 DCLHuffman=Record
  Count:Array[0..DCLMaxBits]of Integer;
  Symbol:Array[0..255]of Integer;
 End;
 ZstdFSEEntry=Record
  Symbol:Byte;
  Bits:Byte;
  NewState:Integer;
 End;
 ZstdFSETable=Record
  TableLog:Integer;
  TableSize:Integer;
  FastMode:Boolean;
  Entry:Array[0..ZstdFSEMaxTableSize-1]of ZstdFSEEntry;
 End;
 ZstdHuffEntry=Record
  Symbol:Byte;
  Bits:Byte;
 End;
 ZstdHuffTable=Record
  TableLog:Integer;
  TableSize:Integer;
  MaxSymbol:Integer;
  Entry:Array[0..ZstdHuffMaxTableSize-1]of ZstdHuffEntry;
  Weight:Array[0..ZstdHuffMaxSymbols-1]of Byte;
 End;
 PZstdSeqChunk=^TZstdSeqChunk;
 TZstdSeqChunk=Array[0..ZstdSeqChunkSize-1]of Byte;
 PZstdSeqBuffer=^TZstdSeqBuffer;
 TZstdSeqBuffer=Record
  Chunks:Array[0..ZstdSeqNumChunks-1]of PZstdSeqChunk;
 End;
 ZstdRevBitStream=Record
  Buf:PZstdSeqBuffer;
  Base,Size,Pos:LongInt;
  Bits:LongInt;
  BitCount:Integer;
 End;
 ZstdSeqTables=Record
  LL,OFs,ML:ZstdFSETable;
  LLMode,OFMode,MLMode:Integer;
  LLRLE,OFRLE,MLRLE:Byte;
  LLValid,OFValid,MLValid:Boolean;
 End;
 BZHuffman=Record
  MinLen,MaxLen:Integer;
  Len:Array[0..BZMaxAlphaSize-1]of Byte;
  Code:Array[0..BZMaxAlphaSize-1]of LongInt;
 End;

Var
 ZipFile:File;
 OutFile:File;
 ArchiveName:String;
 DestDir,Password:String;
 ExcludeList:Array[1..MaxExclude]of String;
 ExcludeCount:Integer;
 CompLeft,UncompSize,ExpectedCRC,OutCRC,OutSize:LongInt;
 BitBuf,BitCount:Integer;
 WindowLo,WindowHi:PWindowHalf;
 WinPos,WindowMask:LongInt;
 CRC32Table:Array[0..255]of LongInt;
 ListMode,VerboseMode,TestMode,OverwriteMode,NeverOverwrite:Boolean;
 JunkPaths,QuietMode,VeryQuietMode,AutoText,CaseInsensitive:Boolean;
 LowerNames,KeepUnicode,FreshenMode,UpdateMode,PipeMode,CatMode:Boolean;
 ShowCommentMode,MoreMode,RestoreAttr,KeepFullPath:Boolean;
 OutputMode,MoreLines,PrevOutByte:Integer;
 ShrinkPrefix:PShrinkIntArray;
 ShrinkSuffix:PShrinkByteArray;
 ShrinkActive:PShrinkBoolArray;
 ShrinkStack:PShrinkByteArray;
 ReduceSize:PFollowerSizeArray;
 ReduceBits:PFollowerSizeArray;
 ReduceFollowers:PFollowerArray;
 BZTT:Array[0..BZMaxChunks-1]of PBZTTChunk;
 BZByte:Array[0..BZMaxChunks-1]of PBZByteChunk;
 BZBitBuf,BZBitCount:Integer;
 BZBlockLimit:LongInt;
 LZDict:Array[0..LZMaxChunks-1]of PLZByteChunk;
 LZLit:Array[0..LZMaxLitContexts-1]of PLZLitContext;
 LZDictSize,LZDictPos,LZRange,LZCode:LongInt;
 LZIsMatch:Array[0..LZNumStates*LZNumPosStatesMax-1]of Word;
 LZIsRep,LZIsRepG0,LZIsRepG1,LZIsRepG2:Array[0..LZNumStates-1]of Word;
 LZIsRep0Long:Array[0..LZNumStates*LZNumPosStatesMax-1]of Word;
 LZPosSlot:Array[0..LZNumLenToPosStates*64-1]of Word;
 LZPosDecoders:Array[0..LZNumFullDistances-LZEndPosModelIndex-1]of Word;
 LZPosAlign:Array[0..LZAlignTableSize-1]of Word;
 LZLenChoice,LZRepLenChoice:Array[0..1]of Word;
 LZLenLow,LZLenMid,LZRepLenLow,LZRepLenMid:Array[0..LZNumPosStatesMax*8-1]of Word;
 LZLenHigh,LZRepLenHigh:Array[0..LZLenHighSymbols-1]of Word;
 TerseBitsAvailable,TerseSavedBits:Integer;
 DCLBitBuf,DCLBitCount,DCLNext:Integer;
 DCLWin:PDCLWindow;
 ZipCryptActive:Boolean;
 ZipKey0,ZipKey1,ZipKey2:LongInt;
 ZstdRep1,ZstdRep2,ZstdRep3:LongInt;

Function Path2Ext(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Path2Ext:=E;
End;

Function UShiftRight(L:LongInt;N:Byte):LongInt;
Var
 I:Byte;
Begin
 For I:=1 to N do L:=(L shr 1)and $7FFFFFFF;
 UShiftRight:=L;
End;

Function LowByte(L:LongInt):Byte;
Begin
 LowByte:=Byte(L and $FF);
End;

Function CRC32Value(C:LongInt;B:Byte):LongInt; forward;
Function ZipDecryptByte(C:Byte):Byte; forward;

Procedure InitCRC32;
Var
 I,J:Integer;
 C:LongInt;
Begin
 For I:=0 to 255 do Begin
  C:=I;
  For J:=0 to 7 do Begin
   If(C and 1)<>0Then C:=UShiftRight(C,1)xor LongInt($EDB88320)
                 Else C:=UShiftRight(C,1);
  End;
  CRC32Table[I]:=C;
 End;
End;

Procedure UpdateCRC32(B:Byte);
Begin
 OutCRC:=CRC32Value(OutCRC,B);
 Inc(OutSize);
End;

Function UpStr(S:String):String;
Var
 I:Integer;
Begin
 For I:=1 to Length(S)do If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 UpStr:=S;
End;

Function LowStr(S:String):String;
Var
 I:Integer;
Begin
 For I:=1 to Length(S)do If S[I] in['A'..'Z']Then S[I]:=Chr(Ord(S[I])+32);
 LowStr:=S;
End;

Function FileExists(S:String):Boolean;
Var
 F:File;
 R:Integer;
Begin
 Assign(F,S);
 {$I-}Reset(F,1);{$I+}
 R:=IoResult;
 If R=0Then Close(F);
 FileExists:=R=0;
End;

Function ZipDateTimeStamp(ZTime,ZDate:Integer):LongInt;
Begin
 ZipDateTimeStamp:=(LongInt(ZDate)shl 16)or LongInt(ZTime);
End;

Function GetFileDateTimeStamp(S:String;Var Stamp:LongInt):Boolean;
Var
 F:File;
 R:Integer;
Begin
 Assign(F,S);
 {$I-}Reset(F,1);{$I+}
 R:=IoResult;
 If R<>0Then Begin
  GetFileDateTimeStamp:=False;
  Exit;
 End;
 GetFTime(F,Stamp);
 Close(F);
 GetFileDateTimeStamp:=True;
End;

Procedure SetFileDateTimeStamp(S:String;Stamp:LongInt);
Var
 F:File;
 R:Integer;
Begin
 Assign(F,S);
 {$I-}Reset(F,1);{$I+}
 R:=IoResult;
 If R<>0Then Exit;
 SetFTime(F,Stamp);
 Close(F);
End;

Function Long2Str(L:LongInt):String;
Var
 S:String;
Begin
 Str(L,S);
 Long2Str:=S;
End;

Function HexDigit(N:Integer):Char;
Begin
 If N<10Then HexDigit:=Chr(Ord('0')+N)
        Else HexDigit:=Chr(Ord('A')+N-10);
End;

Function Hex8(L:LongInt):String;
Var
 I:Integer;
 S:String;
Begin
 S:='';
 For I:=7 downto 0 do S:=S+HexDigit(Integer(UShiftRight(L,I*4)and 15));
 Hex8:=S;
End;

Function SameDWord(A,B:LongInt):Boolean;
Begin
 SameDWord:=Hex8(A)=Hex8(B);
End;

Function CRC32Value(C:LongInt;B:Byte):LongInt;
Begin
 CRC32Value:=UShiftRight(C,8)xor CRC32Table[LowByte(C xor B)];
End;

Function BaseName(S:String):String;
Var
 I,P:Integer;
Begin
 P:=0;
 For I:=1 to Length(S)do If(S[I]='\')or(S[I]='/')Then P:=I;
 If P=0Then BaseName:=S
       Else BaseName:=Copy(S,P+1,255);
End;

Function JoinPath(A,B:String):String;
Begin
 If A=''Then JoinPath:=B
  Else If(A[Length(A)]='\')or(A[Length(A)]='/')Then JoinPath:=A+B
  Else JoinPath:=A+'\'+B;
End;

Procedure MoreWriteLn(S:String);
Var
 K:Char;
Begin
 If VeryQuietMode Then Exit;
 WriteLn(S);
 If MoreMode Then Begin
  Inc(MoreLines);
  If MoreLines>=23 Then Begin
   Write('--More--');
   Read(K);
   WriteLn;
   MoreLines:=0;
  End;
 End;
End;

Function ReverseBits(Code:LongInt;Bits:Integer):LongInt;
Var
 I:Integer;
 R:LongInt;
Begin
 R:=0;
 For I:=1 to Bits do Begin
  R:=(R shl 1)or(Code and 1);
  Code:=Code shr 1;
 End;
 ReverseBits:=R;
End;

Procedure InitWindow(Use64K:Boolean);
Begin
 If WindowLo=NIL Then GetMem(WindowLo,SizeOf(TWindowHalf));
 If Use64K and(WindowHi=NIL)Then GetMem(WindowHi,SizeOf(TWindowHalf));
 If WindowLo=NIL Then Begin
  WriteLn('Memoire insuffisante pour la fenetre ZIP.');
  Halt(1);
 End;
 If Use64K and(WindowHi=NIL)Then Begin
  WriteLn('Memoire insuffisante pour la fenetre Deflate64.');
  Halt(1);
 End;
 FillChar(WindowLo^,SizeOf(TWindowHalf),0);
 If WindowHi<>NIL Then FillChar(WindowHi^,SizeOf(TWindowHalf),0);
 WinPos:=0;
 WindowMask:=$7FFF;
 If Use64K Then WindowMask:=$FFFF;
End;

Function GetWindowByte(Pos:LongInt):Byte;
Begin
 Pos:=Pos and WindowMask;
 If Pos<WindowHalfSize Then GetWindowByte:=WindowLo^[Pos]
  Else
 Begin
  If WindowHi=NIL Then GetWindowByte:=0
                 Else GetWindowByte:=WindowHi^[Pos-WindowHalfSize];
 End;
End;

Procedure SetWindowByte(Pos:LongInt;B:Byte);
Begin
 Pos:=Pos and WindowMask;
 If Pos<WindowHalfSize Then WindowLo^[Pos]:=B
  Else If WindowHi<>NIL Then WindowHi^[Pos-WindowHalfSize]:=B;
End;

Procedure PutOutByte(B:Byte);
Var
 C:Char;
 Count:Word;
Begin
 UpdateCRC32(B);
 If OutputMode=0 Then Begin
  If AutoText and(B=10)and(PrevOutByte<>13)Then Begin
   C:=#13;
   BlockWrite(OutFile,C,1,Count);
  End;
  BlockWrite(OutFile,B,1,Count);
 End
  Else If OutputMode=1 Then Begin
  If AutoText and(B=10)and(PrevOutByte<>13)Then Write(#13);
 Write(Chr(B));
 End;
 PrevOutByte:=B;
 SetWindowByte(WinPos,B);
 WinPos:=(WinPos+1)and WindowMask;
End;

Function ReadZipByte:Byte;
Var
 B:Byte;
 Count:Word;
Begin
 B:=0;
 BlockRead(ZipFile,B,1,Count);
 If Count<>1 Then Begin
  WriteLn('Erreur de lecture du fichier ZIP.');
  Halt(1);
 End;
 ReadZipByte:=B;
End;

Function ReadCompByte:Byte;
Var
 B:Byte;
Begin
 If CompLeft<=0 Then Begin
  WriteLn('Flux compresse trop court.');
  Halt(1);
 End;
 Dec(CompLeft);
 B:=ReadZipByte;
 If ZipCryptActive Then B:=ZipDecryptByte(B);
 ReadCompByte:=B;
End;

Function ReadWordLE:Integer;
Var
 B1,B2:Byte;
Begin
 B1:=ReadZipByte;
 B2:=ReadZipByte;
 ReadWordLE:=B1+256*B2;
End;

Function ReadDWordLE:LongInt;
Var
 B1,B2,B3,B4:LongInt;
Begin
 B1:=ReadZipByte;
 B2:=ReadZipByte;
 B3:=ReadZipByte;
 B4:=ReadZipByte;
 ReadDWordLE:=B1+256*B2+65536*B3+16777216*B4;
End;

Procedure ZipCryptUpdate(B:Byte);
Begin
 ZipKey0:=CRC32Value(ZipKey0,B);
 ZipKey1:=ZipKey1+LowByte(ZipKey0);
 ZipKey1:=ZipKey1*LongInt(134775813)+1;
 ZipKey2:=CRC32Value(ZipKey2,Byte(UShiftRight(ZipKey1,24)and $FF));
End;

Function ZipCryptByte:Byte;
Var
 T:LongInt;
Begin
 T:=(ZipKey2 or 2)and $FFFF;
 ZipCryptByte:=Byte(UShiftRight(T*(T xor 1),8)and $FF);
End;

Function ZipDecryptByte(C:Byte):Byte;
Var
 P:Byte;
Begin
 P:=C xor ZipCryptByte;
 ZipCryptUpdate(P);
 ZipDecryptByte:=P;
End;

Procedure ZipCryptInit(Pwd:String);
Var
 I:Integer;
Begin
 ZipKey0:=LongInt(305419896);
 ZipKey1:=LongInt(591751049);
 ZipKey2:=LongInt(878082192);
 For I:=1 to Length(Pwd)do ZipCryptUpdate(Byte(Ord(Pwd[I])));
End;

Function ReadBit:Integer;
Begin
 If BitCount=0 Then Begin
  BitBuf:=ReadCompByte;
  BitCount:=8;
 End;
 ReadBit:=BitBuf and 1;
 BitBuf:=BitBuf shr 1;
 Dec(BitCount);
End;

Function ReadBits(N:Integer):Integer;
Var
 I,V:Integer;
Begin
 V:=0;
 For I:=0 to N-1 do V:=V or(ReadBit shl I);
 ReadBits:=V;
End;

Function ReadBitsLong(N:Integer):LongInt;
Var
 I:Integer;
 V:LongInt;
Begin
 V:=0;
 For I:=0 to N-1 do If ReadBit<>0 Then V:=V or(LongInt(1)shl I);
 ReadBitsLong:=V;
End;

Procedure AlignByte;
Begin
 BitBuf:=0;
 BitCount:=0;
End;

Procedure BuildHuffman(Var H:Huffman;Var Lengths;N:Integer);
Type
 TLengths=Array[0..MaxSymbols-1]of Byte;
Var
 L:^TLengths;
 Count:Array[0..MaxBits]of Integer;
 NextCode:Array[0..MaxBits]of LongInt;
 I,Bits:Integer;
 Code:LongInt;
Begin
 L:=@Lengths;
 H.NumSymbols:=N;
 For I:=0 to MaxSymbols-1 do Begin
  H.Len[I]:=0;
  H.Code[I]:=0;
 End;
 For I:=0 to MaxBits do Count[I]:=0;
 For I:=0 to N-1 do Begin
  H.Len[I]:=L^[I];
  If H.Len[I]>0Then Inc(Count[H.Len[I]]);
 End;
 Code:=0;
 Count[0]:=0;
 For Bits:=1 to MaxBits do Begin
  Code:=(Code+Count[Bits-1])shl 1;
  NextCode[Bits]:=Code;
 End;
 For I:=0 to N-1 do Begin
  Bits:=H.Len[I];
  If Bits<>0Then Begin
   H.Code[I]:=ReverseBits(NextCode[Bits],Bits);
   Inc(NextCode[Bits]);
  End;
 End;
End;

Procedure BuildHuffmanInvert(Var H:Huffman;Var Lengths;N:Integer);
Type
 TLengths=Array[0..MaxSymbols-1]of Byte;
Var
 L:^TLengths;
 Count:Array[0..MaxBits]of Integer;
 NextCode:Array[0..MaxBits]of LongInt;
 I,Bits:Integer;
 Code,Mask:LongInt;
Begin
 L:=@Lengths;
 H.NumSymbols:=N;
 For I:=0 to MaxSymbols-1 do Begin
  H.Len[I]:=0;
  H.Code[I]:=0;
 End;
 For I:=0 to MaxBits do Count[I]:=0;
 For I:=0 to N-1 do Begin
  H.Len[I]:=L^[I];
  If H.Len[I]>0Then Inc(Count[H.Len[I]]);
 End;
 Code:=0;
 Count[0]:=0;
 For Bits:=1 to MaxBits do Begin
  Code:=(Code+Count[Bits-1])shl 1;
  NextCode[Bits]:=Code;
 End;
 For I:=0 to N-1 do Begin
  Bits:=H.Len[I];
  If Bits<>0Then Begin
   If Bits=16 Then Mask:=$FFFF
              Else Mask:=(LongInt(1)shl Bits)-1;
   H.Code[I]:=ReverseBits((Not NextCode[Bits])and Mask,Bits);
   Inc(NextCode[Bits]);
  End;
 End;
End;

Function DecodeSymbol(Var H:Huffman):Integer;
Var
 Len,Sym:Integer;
 Code:LongInt;
Begin
 Code:=0;
 For Len:=1 to MaxBits do Begin
  If ReadBit<>0 Then Code:=Code or(LongInt(1)shl(Len-1));
  For Sym:=0 to H.NumSymbols-1 do Begin
   If(H.Len[Sym]=Len)and(H.Code[Sym]=Code)Then Begin
    DecodeSymbol:=Sym;
    Exit;
   End
  End;
 End;
 WriteLn('Code Huffman invalide.');
 Halt(1);
 DecodeSymbol:=0;
End;

Procedure BuildFixedTrees(Var LitLen,Dist:Huffman);
Var
 L1,L2:Array[0..MaxSymbols-1]of Byte;
 I:Integer;
Begin
 For I:=0 to MaxSymbols-1 do Begin
  L1[I]:=0;
  L2[I]:=0;
 End;
 For I:=0 to 143 do L1[I]:=8;
 For I:=144 to 255 do L1[I]:=9;
 For I:=256 to 279 do L1[I]:=7;
 For I:=280 to 287 do L1[I]:=8;
 For I:=0 to 31 do L2[I]:=5;
 BuildHuffman(LitLen,L1,288);
 BuildHuffman(Dist,L2,32);
End;

Procedure BuildDynamicTrees(Var LitLen,Dist:Huffman);
Const
 Order:Array[0..18]of Byte=(16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15);
Var
 HLIT,HDIST,HCLEN:Integer;
 CodeLenLengths:Array[0..MaxSymbols-1]of Byte;
 Lengths:Array[0..MaxSymbols-1]of Byte;
 CodeLenTree:Huffman;
 I,Sym,Rep,Prev,Total:Integer;
Begin
 For I:=0 to MaxSymbols-1 do Begin
  CodeLenLengths[I]:=0;
  Lengths[I]:=0;
 End;
 HLIT:=ReadBits(5)+257;
 HDIST:=ReadBits(5)+1;
 HCLEN:=ReadBits(4)+4;
 For I:=0 to HCLEN-1 do CodeLenLengths[Order[I]]:=ReadBits(3);
 BuildHuffman(CodeLenTree,CodeLenLengths,19);
 Total:=HLIT+HDIST;
 I:=0;
 Prev:=0;
 While I<Total do Begin
  Sym:=DecodeSymbol(CodeLenTree);
  If Sym<=15 Then Begin
   Lengths[I]:=Sym;
   Prev:=Sym;
   Inc(I);
  End
   Else If Sym=16 Then Begin
   Rep:=ReadBits(2)+3;
   While(Rep>0)and(I<Total)do Begin
    Lengths[I]:=Prev;
    Inc(I);
    Dec(Rep);
   End;
  End
   Else If Sym=17 Then Begin
   Rep:=ReadBits(3)+3;
   Prev:=0;
   While(Rep>0)and(I<Total)do Begin
    Lengths[I]:=0;
    Inc(I);
    Dec(Rep);
   End;
  End
   Else If Sym=18 Then Begin
   Rep:=ReadBits(7)+11;
   Prev:=0;
   While(Rep>0)and(I<Total)do Begin
    Lengths[I]:=0;
    Inc(I);
    Dec(Rep);
   End;
  End
   Else
  Begin
   WriteLn('Longueur Huffman dynamique invalide.');
   Halt(1);
  End;
 End;
 BuildHuffman(LitLen,Lengths,HLIT);
 For I:=0 to HDIST-1 do Lengths[I]:=Lengths[HLIT+I];
 BuildHuffman(Dist,Lengths,HDIST);
End;

Procedure InflateCodes(Var LitLen,Dist:Huffman);
Const
 LenBase:Array[0..28]of Integer=(
  3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,
  35,43,51,59,67,83,99,115,131,163,195,227,258);
 LenExtra:Array[0..28]of Integer=(
  0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,
  3,3,3,3,4,4,4,4,5,5,5,5,0);
 DistBase:Array[0..29]of Integer=(
  1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,
  193,257,385,513,769,1025,1537,2049,3073,4097,
  6145,8193,12289,16385,24577);
 DistExtra:Array[0..29]of Integer=(
  0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,
  6,7,7,8,8,9,9,10,10,11,11,12,12,13,13);
Var
 Sym,Len,Distance,I,WinRead:Integer;
 B:Byte;
Begin
 Repeat
  Sym:=DecodeSymbol(LitLen);
  If Sym<256Then PutOutByte(Sym)
   Else If Sym=256Then Exit
   Else
  Begin
   If(Sym<257)or(Sym>285)Then Begin
    WriteLn('Longueur Deflate invalide.');
    Halt(1);
   End;
   Sym:=Sym-257;
   Len:=LenBase[Sym];
   If LenExtra[Sym]>0Then Inc(Len,ReadBits(LenExtra[Sym]));
   Sym:=DecodeSymbol(Dist);
   If(Sym<0)or(Sym>29)Then Begin
    WriteLn('Distance Deflate invalide.');
    Halt(1);
   End;
   Distance:=DistBase[Sym];
   If DistExtra[Sym]>0Then Inc(Distance,ReadBits(DistExtra[Sym]));
   For I:=1 to Len do Begin
    WinRead:=(WinPos-Distance)and $7FFF;
    B:=GetWindowByte(WinRead);
    PutOutByte(B);
   End;
  End;
 Until False;
End;

Procedure Inflate64Codes(Var LitLen,Dist:Huffman);
Const
 LenBase:Array[0..28]of LongInt=(
  3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,
  35,43,51,59,67,83,99,115,131,163,195,227,3);
 LenExtra:Array[0..28]of Integer=(
  0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,
  3,3,3,3,4,4,4,4,5,5,5,5,16);
 DistBase:Array[0..31]of LongInt=(
  1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,
  193,257,385,513,769,1025,1537,2049,3073,4097,
  6145,8193,12289,16385,24577,32769,49153);
 DistExtra:Array[0..31]of Integer=(
  0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,
  6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,14,14);
Var
 Sym:Integer;
 Len,Distance,I,WinRead:LongInt;
 B:Byte;
Begin
 Repeat
  Sym:=DecodeSymbol(LitLen);
  If Sym<256Then PutOutByte(Sym)
   Else If Sym=256Then Exit
   Else
  Begin
   If(Sym<257)or(Sym>285)Then Begin
    WriteLn('Longueur Deflate64 invalide.');
    Halt(1);
   End;
   Sym:=Sym-257;
   Len:=LenBase[Sym];
   If LenExtra[Sym]>0Then Inc(Len,ReadBitsLong(LenExtra[Sym]));
   Sym:=DecodeSymbol(Dist);
   If(Sym<0)or(Sym>31)Then Begin
    WriteLn('Distance Deflate64 invalide.');
    Halt(1);
   End;
   Distance:=DistBase[Sym];
   If DistExtra[Sym]>0Then Inc(Distance,ReadBitsLong(DistExtra[Sym]));
   If Distance>OutSize Then Begin
    WriteLn('Reference Deflate64 invalide.');
    Halt(1);
   End;
   I:=1;
   While I<=Len do Begin
    WinRead:=(WinPos-Distance)and $FFFF;
    B:=GetWindowByte(WinRead);
    PutOutByte(B);
    Inc(I);
   End;
  End;
 Until False;
End;

Procedure InflateStored;
Var
 Len,NLen,I:Integer;
Begin
 AlignByte;
 Len:=ReadBits(16);
 NLen:=ReadBits(16);
 If ((Len xor NLen)and $FFFF)<>$FFFFThen Begin
  WriteLn('Bloc Deflate stocke invalide.');
  Halt(1);
 End;
 For I:=1 to Len do PutOutByte(ReadCompByte);
End;

Procedure InflateDeflate;
Var
 FinalBlock,BType:Integer;
 LitLen,Dist:Huffman;
Begin
 BitBuf:=0;
 BitCount:=0;
 InitWindow(False);
 Repeat
  FinalBlock:=ReadBit;
  BType:=ReadBits(2);
  Case BType of
   0:InflateStored;
   1:Begin
      BuildFixedTrees(LitLen,Dist);
      InflateCodes(LitLen,Dist);
     End;
   2:Begin
      BuildDynamicTrees(LitLen,Dist);
      InflateCodes(LitLen,Dist);
     End;
  Else
   WriteLn('Type de bloc Deflate invalide.');
   Halt(1);
  End;
 Until FinalBlock<>0;
 AlignByte;
End;

Procedure InflateDeflate64;
Var
 FinalBlock,BType:Integer;
 LitLen,Dist:Huffman;
Begin
 BitBuf:=0;
 BitCount:=0;
 InitWindow(True);
 Repeat
  FinalBlock:=ReadBit;
  BType:=ReadBits(2);
  Case BType of
   0:InflateStored;
   1:Begin
      BuildFixedTrees(LitLen,Dist);
      Inflate64Codes(LitLen,Dist);
     End;
   2:Begin
      BuildDynamicTrees(LitLen,Dist);
      Inflate64Codes(LitLen,Dist);
     End;
  Else
   WriteLn('Type de bloc Deflate64 invalide.');
   Halt(1);
  End;
 Until FinalBlock<>0;
 AlignByte;
End;

Function ULess(A,B:LongInt):Boolean;
Begin
 ULess:=(A xor LongInt($80000000))<(B xor LongInt($80000000));
End;

Function LZReadByte:Byte;
Begin
 LZReadByte:=ReadCompByte;
End;

Function LZReadWordLE:Integer;
Var
 B1,B2:Integer;
Begin
 B1:=LZReadByte;
 B2:=LZReadByte;
 LZReadWordLE:=B1+256*B2;
End;

Function LZReadDWordLE:LongInt;
Var
 B1,B2,B3,B4:LongInt;
Begin
 B1:=LZReadByte;
 B2:=LZReadByte;
 B3:=LZReadByte;
 B4:=LZReadByte;
 LZReadDWordLE:=B1+256*B2+65536*B3+16777216*B4;
End;

Procedure LZFree;
Var
 I:Integer;
Begin
 For I:=0 to LZMaxChunks-1 do If LZDict[I]<>NIL Then Begin
  FreeMem(LZDict[I],SizeOf(TLZByteChunk));
  LZDict[I]:=NIL;
 End;
 For I:=0 to LZMaxLitContexts-1 do If LZLit[I]<>NIL Then Begin
  FreeMem(LZLit[I],SizeOf(TLZLitContext));
  LZLit[I]:=NIL;
 End;
End;

Procedure LZAllocDict(Size:LongInt);
Var
 I,Need:Integer;
Begin
 If Size<1 Then Size:=1;
 If Size>UncompSize Then Size:=UncompSize;
 If Size<1 Then Size:=1;
 LZDictSize:=Size;
 Need:=(Size+LZChunkSize-1)div LZChunkSize;
 If Need>LZMaxChunks Then Begin
  WriteLn('Dictionnaire LZMA trop grand pour ce modele memoire.');
  Halt(1);
 End;
 For I:=0 to LZMaxChunks-1 do LZDict[I]:=NIL;
 For I:=0 to Need-1 do Begin
  GetMem(LZDict[I],SizeOf(TLZByteChunk));
  If LZDict[I]=NIL Then Begin
   WriteLn('Memoire insuffisante pour LZMA.');
   Halt(1);
  End;
  FillChar(LZDict[I]^,SizeOf(TLZByteChunk),0);
 End;
 LZDictPos:=0;
End;

Procedure LZAllocLiterals(NumContexts:Integer);
Var
 I,J:Integer;
Begin
 If NumContexts>LZMaxLitContexts Then Begin
  LZFree;
  WriteLn('Contexte litteral LZMA trop grand pour Turbo Pascal.');
  Halt(1);
 End;
 For I:=0 to LZMaxLitContexts-1 do LZLit[I]:=NIL;
 For I:=0 to NumContexts-1 do Begin
  GetMem(LZLit[I],SizeOf(TLZLitContext));
  If LZLit[I]=NIL Then Begin
   LZFree;
   WriteLn('Memoire insuffisante pour les litteraux LZMA.');
   Halt(1);
  End;
  For J:=0 to LZLitContextSize-1 do LZLit[I]^[J]:=LZBitModelTotal div 2;
 End;
End;

Procedure LZSetDictByte(Pos:LongInt;B:Byte);
Var
 C,O:Integer;
Begin
 Pos:=Pos mod LZDictSize;
 C:=Pos div LZChunkSize;
 O:=Pos mod LZChunkSize;
 LZDict[C]^[O]:=B;
End;

Function LZGetDictByte(Pos:LongInt):Byte;
Var
 C,O:Integer;
Begin
 Pos:=Pos mod LZDictSize;
 If Pos<0 Then Inc(Pos,LZDictSize);
 C:=Pos div LZChunkSize;
 O:=Pos mod LZChunkSize;
 LZGetDictByte:=LZDict[C]^[O];
End;

Procedure LZPutByte(B:Byte);
Begin
 PutOutByte(B);
 LZSetDictByte(LZDictPos,B);
 Inc(LZDictPos);
 If LZDictPos>=LZDictSize Then LZDictPos:=0;
End;

Procedure LZInitProbs;
Var
 I:Integer;
Begin
 For I:=0 to High(LZIsMatch)do LZIsMatch[I]:=LZBitModelTotal div 2;
 For I:=0 to High(LZIsRep)do Begin
  LZIsRep[I]:=LZBitModelTotal div 2;
  LZIsRepG0[I]:=LZBitModelTotal div 2;
  LZIsRepG1[I]:=LZBitModelTotal div 2;
  LZIsRepG2[I]:=LZBitModelTotal div 2;
 End;
 For I:=0 to High(LZIsRep0Long)do LZIsRep0Long[I]:=LZBitModelTotal div 2;
 For I:=0 to High(LZPosSlot)do LZPosSlot[I]:=LZBitModelTotal div 2;
 For I:=0 to High(LZPosDecoders)do LZPosDecoders[I]:=LZBitModelTotal div 2;
 For I:=0 to High(LZPosAlign)do LZPosAlign[I]:=LZBitModelTotal div 2;
 For I:=0 to 1 do Begin
  LZLenChoice[I]:=LZBitModelTotal div 2;
  LZRepLenChoice[I]:=LZBitModelTotal div 2;
 End;
 For I:=0 to High(LZLenLow)do Begin
  LZLenLow[I]:=LZBitModelTotal div 2;
  LZLenMid[I]:=LZBitModelTotal div 2;
  LZRepLenLow[I]:=LZBitModelTotal div 2;
  LZRepLenMid[I]:=LZBitModelTotal div 2;
 End;
 For I:=0 to High(LZLenHigh)do Begin
  LZLenHigh[I]:=LZBitModelTotal div 2;
  LZRepLenHigh[I]:=LZBitModelTotal div 2;
 End;
End;

Procedure LZRangeInit;
Var
 I:Integer;
Begin
 LZCode:=0;
 LZRange:=LongInt($FFFFFFFF);
 For I:=1 to 5 do LZCode:=(LZCode shl 8)or LZReadByte;
End;

Procedure LZNormalize;
Begin
 While ULess(LZRange,LongInt($01000000))do Begin
  LZRange:=LZRange shl 8;
  LZCode:=(LZCode shl 8)or LZReadByte;
 End;
End;

Function LZDecodeBit(Var Prob:Word):Integer;
Var
 Bound:LongInt;
Begin
 Bound:=UShiftRight(LZRange,11)*Prob;
 If ULess(LZCode,Bound)Then Begin
  LZRange:=Bound;
  Prob:=Prob+((LZBitModelTotal-Prob)shr LZMoveBits);
  LZNormalize;
  LZDecodeBit:=0;
 End
  Else
 Begin
  LZCode:=LZCode-Bound;
  LZRange:=LZRange-Bound;
  Prob:=Prob-(Prob shr LZMoveBits);
  LZNormalize;
  LZDecodeBit:=1;
 End;
End;

Function LZDecodeDirectBits(NumBits:Integer):LongInt;
Var
 I:Integer;
 Res:LongInt;
Begin
 Res:=0;
 For I:=1 to NumBits do Begin
  LZRange:=UShiftRight(LZRange,1);
  Res:=Res shl 1;
  If Not ULess(LZCode,LZRange)Then Begin
   LZCode:=LZCode-LZRange;
   Res:=Res or 1;
  End;
  LZNormalize;
 End;
 LZDecodeDirectBits:=Res;
End;

Function LZBitTreeDecode(P:Pointer;Offset,NumBits:Integer):Integer;
Var
 A:PWordArray;
 M,I:Integer;
Begin
 A:=P;
 M:=1;
 For I:=1 to NumBits do M:=(M shl 1)or LZDecodeBit(A^[Offset+M]);
 LZBitTreeDecode:=M-(1 shl NumBits);
End;

Function LZReverseBitTreeDecode(P:Pointer;Offset,NumBits:Integer):LongInt;
Var
 A:PWordArray;
 M,I,Bit:Integer;
 Res:LongInt;
Begin
 A:=P;
 M:=1;
 Res:=0;
 For I:=0 to NumBits-1 do Begin
  Bit:=LZDecodeBit(A^[Offset+M]);
  M:=(M shl 1)or Bit;
  Res:=Res or(LongInt(Bit)shl I);
 End;
 LZReverseBitTreeDecode:=Res;
End;

Function LZDecodeLen(PChoice,PLow,PMid,PHigh:Pointer;PosState:Integer):Integer;
Var
 Choice,Low,Mid,High:PWordArray;
Begin
 Choice:=PChoice;
 Low:=PLow;
 Mid:=PMid;
 High:=PHigh;
 If LZDecodeBit(Choice^[0])=0 Then
  LZDecodeLen:=LZBitTreeDecode(Low,PosState*LZLenLowSymbols,3)
 Else If LZDecodeBit(Choice^[1])=0 Then
  LZDecodeLen:=LZLenLowSymbols+
   LZBitTreeDecode(Mid,PosState*LZLenMidSymbols,3)
 Else
  LZDecodeLen:=LZLenLowSymbols+LZLenMidSymbols+
   LZBitTreeDecode(High,0,8);
End;

Function LZStateIsChar(State:Integer):Boolean;
Begin
 LZStateIsChar:=State<7;
End;

Function LZLenToPosState(Len:Integer):Integer;
Begin
 Len:=Len-2;
 If Len<0 Then Len:=0;
 If Len<4 Then LZLenToPosState:=Len
          Else LZLenToPosState:=3;
End;

Function LZDecodeLiteral(Lc,Lp,State:Integer;Rep0:LongInt;Prev:Byte):Byte;
Var
 Ctx,Symbol,Bit,MatchBit:Integer;
 MatchByte:Byte;
 Lit:PLZLitContext;
Begin
 Ctx:=((OutSize and((1 shl Lp)-1))shl Lc)+(Prev shr(8-Lc));
 Lit:=LZLit[Ctx];
 Symbol:=1;
 If Not LZStateIsChar(State)Then Begin
  MatchByte:=LZGetDictByte(LZDictPos-Rep0-1);
  Repeat
   MatchBit:=(MatchByte shr 7)and 1;
   MatchByte:=Byte((MatchByte shl 1)and $FF);
   Bit:=LZDecodeBit(Lit^[((1+MatchBit)shl 8)+Symbol]);
   Symbol:=(Symbol shl 1)or Bit;
   If MatchBit<>Bit Then Break;
  Until Symbol>=256;
 End;
 While Symbol<256 do Symbol:=(Symbol shl 1)or LZDecodeBit(Lit^[Symbol]);
 LZDecodeLiteral:=Byte(Symbol-256);
End;

Procedure InflateLZMA;
Var
 Version,PropSize:Integer;
 Props:Array[0..4]of Byte;
 Prop,DictProp:LongInt;
 Lc,Lp,Pb,NumLitContexts,PosStateMask,PosState:Integer;
 State,Len,LenState,PosSlot,NumDirectBits:Integer;
 Rep0,Rep1,Rep2,Rep3,Dist,I:LongInt;
 Prev,B:Byte;
 Sym:Integer;
Begin
 InitWindow(False);
 Version:=LZReadWordLE;
 If Version=0 Then Begin End;
 PropSize:=LZReadWordLE;
 If PropSize<>5 Then Begin
  WriteLn('Proprietes LZMA ZIP non supportees.');
  Halt(1);
 End;
 For Sym:=0 to 4 do Props[Sym]:=LZReadByte;
 Prop:=Props[0];
 Lc:=Prop mod 9;
 Prop:=Prop div 9;
 Lp:=Prop mod 5;
 Pb:=Prop div 5;
 If(Lc>8)or(Lp>4)or(Pb>4)or(Lc+Lp>4)Then Begin
  WriteLn('Parametres LZMA trop grands pour ce modele memoire.');
  Halt(1);
 End;
 DictProp:=Props[1]+256*LongInt(Props[2])+65536*LongInt(Props[3])+
  16777216*LongInt(Props[4]);
 LZAllocDict(DictProp);
 NumLitContexts:=1 shl(Lc+Lp);
 LZAllocLiterals(NumLitContexts);
 LZInitProbs;
 LZRangeInit;
 PosStateMask:=(1 shl Pb)-1;
 State:=0;
 Rep0:=0; Rep1:=0; Rep2:=0; Rep3:=0;
 Prev:=0;
 While OutSize<UncompSize do Begin
  PosState:=OutSize and PosStateMask;
  If LZDecodeBit(LZIsMatch[State*LZNumPosStatesMax+PosState])=0 Then Begin
   B:=LZDecodeLiteral(Lc,Lp,State,Rep0,Prev);
   LZPutByte(B);
   Prev:=B;
   If State<4 Then State:=0
    Else If State<10 Then Dec(State,3)
    Else Dec(State,6);
  End
   Else
  Begin
   If LZDecodeBit(LZIsRep[State])<>0 Then Begin
    If LZDecodeBit(LZIsRepG0[State])=0 Then Begin
     If LZDecodeBit(LZIsRep0Long[State*LZNumPosStatesMax+PosState])=0 Then Begin
      If State<7 Then State:=9 Else State:=11;
      Len:=1;
     End
      Else Len:=LZDecodeLen(@LZRepLenChoice,@LZRepLenLow,
       @LZRepLenMid,@LZRepLenHigh,PosState)+2;
    End
     Else
    Begin
     If LZDecodeBit(LZIsRepG1[State])=0 Then Dist:=Rep1
      Else Begin
       If LZDecodeBit(LZIsRepG2[State])=0 Then Dist:=Rep2
        Else Begin
         Dist:=Rep3;
         Rep3:=Rep2;
        End;
       Rep2:=Rep1;
      End;
     Rep1:=Rep0;
     Rep0:=Dist;
     Len:=LZDecodeLen(@LZRepLenChoice,@LZRepLenLow,
      @LZRepLenMid,@LZRepLenHigh,PosState)+2;
    End;
    If Len<>1 Then If State<7 Then State:=8 Else State:=11;
   End
    Else
   Begin
    Rep3:=Rep2;
    Rep2:=Rep1;
    Rep1:=Rep0;
    Len:=LZDecodeLen(@LZLenChoice,@LZLenLow,@LZLenMid,@LZLenHigh,PosState)+2;
    LenState:=LZLenToPosState(Len);
    PosSlot:=LZBitTreeDecode(@LZPosSlot,LenState*64,6);
    If PosSlot>=LZStartPosModelIndex Then Begin
     NumDirectBits:=(PosSlot shr 1)-1;
     Rep0:=(LongInt(2)or(PosSlot and 1))shl NumDirectBits;
     If PosSlot<LZEndPosModelIndex Then
      Inc(Rep0,LZReverseBitTreeDecode(@LZPosDecoders,
       Rep0-PosSlot-1,NumDirectBits))
     Else Begin
      Inc(Rep0,LZDecodeDirectBits(NumDirectBits-LZNumAlignBits)
       shl LZNumAlignBits);
      Inc(Rep0,LZReverseBitTreeDecode(@LZPosAlign,0,LZNumAlignBits));
     End;
    End
     Else Rep0:=PosSlot;
    If State<7 Then State:=7 Else State:=10;
   End;
   If(Rep0<0)or(Rep0>=OutSize)Then Begin
    LZFree;
    WriteLn('Reference LZMA invalide.');
    Halt(1);
   End;
   For I:=1 to Len do Begin
    B:=LZGetDictByte(LZDictPos-Rep0-1);
    LZPutByte(B);
    Prev:=B;
   End;
  End;
 End;
 LZFree;
End;

Function DCLBits(Need:Integer):Integer;
Var
 Val:Integer;
Begin
 Val:=DCLBitBuf;
 While DCLBitCount<Need do Begin
  Val:=Val or(Integer(ReadCompByte)shl DCLBitCount);
  Inc(DCLBitCount,8);
 End;
 DCLBitBuf:=Val shr Need;
 Dec(DCLBitCount,Need);
 If Need=0 Then DCLBits:=0
           Else DCLBits:=Val and((1 shl Need)-1);
End;

Function DCLDecode(Var H:DCLHuffman):Integer;
Var
 Len,Code,First,Cnt,Index:Integer;
Begin
 Code:=0;
 First:=0;
 Index:=0;
 For Len:=1 to DCLMaxBits do Begin
  Code:=Code or(DCLBits(1)xor 1);
  Cnt:=H.Count[Len];
  If Code<First+Cnt Then Begin
   DCLDecode:=H.Symbol[Index+(Code-First)];
   Exit;
  End;
  Inc(Index,Cnt);
  Inc(First,Cnt);
  First:=First shl 1;
  Code:=Code shl 1;
 End;
 WriteLn('Code DCL Implode invalide.');
 Halt(1);
 DCLDecode:=0;
End;

Procedure DCLConstruct(Var H:DCLHuffman;Var Rep;RepCount:Integer);
Type
 TRep=Array[0..255]of Byte;
Var
 R:^TRep;
 Length:Array[0..255]of Integer;
 Offs:Array[0..DCLMaxBits]of Integer;
 I,Len,Left,Symbol,N:Integer;
Begin
 R:=@Rep;
 Symbol:=0;
 For I:=0 to RepCount-1 do Begin
  Len:=R^[I];
  Left:=(Len shr 4)+1;
  Len:=Len and 15;
  While Left>0 do Begin
   Length[Symbol]:=Len;
   Inc(Symbol);
   Dec(Left);
  End;
 End;
 N:=Symbol;
 For Len:=0 to DCLMaxBits do H.Count[Len]:=0;
 For Symbol:=0 to N-1 do Inc(H.Count[Length[Symbol]]);
 Left:=1;
 For Len:=1 to DCLMaxBits do Begin
  Left:=Left shl 1;
  Dec(Left,H.Count[Len]);
  If Left<0 Then Begin
   WriteLn('Table DCL Implode invalide.');
   Halt(1);
  End;
 End;
 Offs[1]:=0;
 For Len:=1 to DCLMaxBits-1 do Offs[Len+1]:=Offs[Len]+H.Count[Len];
 For Symbol:=0 to N-1 do If Length[Symbol]<>0 Then Begin
  H.Symbol[Offs[Length[Symbol]]]:=Symbol;
  Inc(Offs[Length[Symbol]]);
 End;
End;

Procedure DCLPutByte(B:Byte);
Begin
 PutOutByte(B);
 DCLWin^[DCLNext]:=B;
 DCLNext:=(DCLNext+1)and $0FFF;
End;

Procedure InflateDCLImplode;
Const
 LitLen:Array[0..97]of Byte=(
  11,124,8,7,28,7,188,13,76,4,10,8,12,10,12,10,8,23,8,
  9,7,6,7,8,7,6,55,8,23,24,12,11,7,9,11,12,6,7,22,5,
  7,24,6,11,9,6,7,22,7,11,38,7,9,8,25,11,8,11,9,12,
  8,12,5,38,5,38,5,11,7,5,6,21,6,10,53,8,7,24,10,27,
  44,253,253,253,252,252,252,13,12,45,12,45,12,61,12,45,
  44,173);
 LenLen:Array[0..5]of Byte=(2,35,36,53,38,23);
 DistLen:Array[0..6]of Byte=(2,20,53,230,247,151,248);
 Base:Array[0..15]of Integer=(
  3,2,4,5,6,7,8,9,10,12,16,24,40,72,136,264);
 Extra:Array[0..15]of Integer=(
  0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8);
Var
 LitCode,LenCode,DistCode:DCLHuffman;
 Lit,Dict,Symbol,Len,Dist,CopyBits,I,FromPos:Integer;
 B:Byte;
Begin
 InitWindow(False);
 If DCLWin=NIL Then GetMem(DCLWin,SizeOf(TDCLWindow));
 If DCLWin=NIL Then Begin
  WriteLn('Memoire insuffisante pour DCL Implode.');
  Halt(1);
 End;
 FillChar(DCLWin^,SizeOf(TDCLWindow),0);
 DCLBitBuf:=0;
 DCLBitCount:=0;
 DCLNext:=0;
 DCLConstruct(LitCode,LitLen,SizeOf(LitLen));
 DCLConstruct(LenCode,LenLen,SizeOf(LenLen));
 DCLConstruct(DistCode,DistLen,SizeOf(DistLen));
 Lit:=DCLBits(8);
 If Lit>1 Then Begin
  WriteLn('En-tete DCL Implode invalide.');
  Halt(1);
 End;
 Dict:=DCLBits(8);
 If(Dict<4)or(Dict>6)Then Begin
  WriteLn('Dictionnaire DCL Implode invalide.');
  Halt(1);
 End;
 While True do Begin
  If DCLBits(1)<>0 Then Begin
   Symbol:=DCLDecode(LenCode);
   Len:=Base[Symbol]+DCLBits(Extra[Symbol]);
   If Len=519 Then Break;
   If Len=2 Then CopyBits:=2 Else CopyBits:=Dict;
   Dist:=(DCLDecode(DistCode)shl CopyBits)+DCLBits(CopyBits)+1;
   If Dist>OutSize Then Begin
    WriteLn('Reference DCL Implode invalide.');
    Halt(1);
   End;
   For I:=1 to Len do Begin
    FromPos:=(DCLNext-Dist)and $0FFF;
    B:=DCLWin^[FromPos];
    DCLPutByte(B);
   End;
  End
   Else
  Begin
   If Lit<>0 Then Symbol:=DCLDecode(LitCode)
             Else Symbol:=DCLBits(8);
   DCLPutByte(Byte(Symbol));
  End;
 End;
 FreeMem(DCLWin,SizeOf(TDCLWindow));
 DCLWin:=NIL;
End;

Function TerseReadByte:Byte;
Begin
 TerseReadByte:=ReadCompByte;
End;

Function TerseReadWordBE:Integer;
Var
 B1,B2:Integer;
Begin
 B1:=TerseReadByte;
 B2:=TerseReadByte;
 TerseReadWordBE:=B1*256+B2;
End;

Function TerseReadDWordBE:LongInt;
Var
 B1,B2,B3,B4:LongInt;
Begin
 B1:=TerseReadByte;
 B2:=TerseReadByte;
 B3:=TerseReadByte;
 B4:=TerseReadByte;
 TerseReadDWordBE:=(((B1*256)+B2)*256+B3)*256+B4;
End;

Function TerseGetBlok:Integer;
Var
 B1,B2:Integer;
Begin
 If TerseBitsAvailable=0 Then Begin
  If CompLeft<=0 Then Begin
   TerseGetBlok:=TerseEOF;
   Exit;
  End;
  B1:=TerseReadByte;
  If CompLeft<=0 Then Begin
   WriteLn('Flux TERSE tronque.');
   Halt(1);
  End;
  B2:=TerseReadByte;
  TerseSavedBits:=B2 and $0F;
  TerseBitsAvailable:=4;
  TerseGetBlok:=(B1 shl 4)or(B2 shr 4);
 End
  Else
 Begin
  If CompLeft<=0 Then Begin
   TerseGetBlok:=TerseEOF;
   Exit;
  End;
  B2:=TerseReadByte;
  TerseBitsAvailable:=0;
  TerseGetBlok:=(TerseSavedBits shl 8)or B2;
 End;
End;

Procedure TersePutChar(X:Integer);
Begin
 If(X=0)or(X=TerseRecordMark)Then Exit;
 If(X<0)or(X>256)Then Begin
  WriteLn('Caractere TERSE invalide.');
  Halt(1);
 End;
 PutOutByte(Byte(X-1));
End;

Procedure InflateTersePack;
Var
 Father,CharExt,Backward,Forward:PTerseIntArray;
 H1,H2,X,D,Y,Q,R,E,P,H:Integer;
Begin
 GetMem(Father,SizeOf(TTerseIntArray));
 GetMem(CharExt,SizeOf(TTerseIntArray));
 GetMem(Backward,SizeOf(TTerseIntArray));
 GetMem(Forward,SizeOf(TTerseIntArray));
 If(Father=NIL)or(CharExt=NIL)or(Backward=NIL)or(Forward=NIL)Then Begin
  WriteLn('Memoire insuffisante pour TERSE PACK.');
  Halt(1);
 End;
 H2:=1+Ord(' ');
 For H1:=258 to 4095 do Begin
  Father^[H1]:=H2;
  CharExt^[H1]:=1+Ord(' ');
  H2:=H1;
 End;
 For H1:=258 to 4094 do Begin
  Backward^[H1+1]:=H1;
  Forward^[H1]:=H1+1;
 End;
 Backward^[0]:=4095;
 Forward^[0]:=258;
 Backward^[258]:=0;
 Forward^[4095]:=0;
 X:=0;
 D:=TerseGetBlok;
 While D<>TerseEOF do Begin
  H:=0;
  Y:=Backward^[0];
  Q:=Backward^[Y];
  Backward^[0]:=Q;
  Forward^[Q]:=0;
  H:=Y;
  P:=0;
  While D>257 do Begin
   Q:=Forward^[D];
   R:=Backward^[D];
   Forward^[R]:=Q;
   Backward^[Q]:=R;
   Forward^[D]:=H;
   Backward^[H]:=D;
   H:=D;
   E:=Father^[D];
   Father^[D]:=P;
   P:=D;
   D:=E;
  End;
  Q:=Forward^[0];
  Forward^[Y]:=Q;
  Backward^[Q]:=Y;
  Forward^[0]:=H;
  Backward^[H]:=0;
  CharExt^[X]:=D;
  TersePutChar(D);
  X:=Y;
  While P<>0 do Begin
   E:=Father^[P];
   TersePutChar(CharExt^[P]);
   Father^[P]:=D;
   D:=P;
   P:=E;
  End;
  Father^[Y]:=D;
  D:=TerseGetBlok;
 End;
 FreeMem(Father,SizeOf(TTerseIntArray));
 FreeMem(CharExt,SizeOf(TTerseIntArray));
 FreeMem(Backward,SizeOf(TTerseIntArray));
 FreeMem(Forward,SizeOf(TTerseIntArray));
End;

Procedure InflateTerseSpack;
Var
 Tree:PTerseTreeArray;
 Stack:PTerseStackArray;
 TreeAvail,Node:Integer;

 Procedure TreeInit;
 Var
  I:Integer;
 Begin
  For I:=0 to TerseTreeSize do Begin
   Tree^[I].Left:=TerseNone;
   Tree^[I].Right:=TerseNone;
   Tree^[I].Back:=0;
   Tree^[I].NextCount:=TerseNone;
  End;
  I:=0;
  While I<=TerseCodeSize do Begin
   Tree^[I].Left:=TerseNone;
   Tree^[I].Right:=I;
   Inc(I);
  End;
  For I:=TerseCodeSize+1 to TerseTreeSize-1 do Begin
   Tree^[I].NextCount:=I+1;
   Tree^[I].Left:=TerseNone;
   Tree^[I].Right:=TerseNone;
  End;
  Tree^[TerseTreeSize].NextCount:=TerseNone;
  Tree^[0].NextCount:=0;
  Tree^[0].Back:=0;
  For I:=1 to TerseCodeSize do Tree^[I].NextCount:=TerseNone;
  TreeAvail:=TerseCodeSize+1;
 End;

 Function GetTreeNode:Integer;
 Begin
  Node:=TreeAvail;
  TreeAvail:=Tree^[Node].NextCount;
  GetTreeNode:=Node;
 End;

 Procedure LruAdd(N:Integer);
 Var
  B:Integer;
 Begin
  B:=Tree^[0].Back;
  Tree^[N].NextCount:=0;
  Tree^[0].Back:=N;
  Tree^[N].Back:=B;
  Tree^[B].NextCount:=N;
 End;

 Procedure DeleteRef(DRef:Integer); forward;

 Procedure LruKill;
 Var
  P,Q,R:Integer;
 Begin
  P:=Tree^[0].NextCount;
  Q:=Tree^[P].NextCount;
  R:=Tree^[P].Back;
  Tree^[Q].Back:=R;
  Tree^[R].NextCount:=Q;
  DeleteRef(Tree^[P].Left);
  DeleteRef(Tree^[P].Right);
  Tree^[P].NextCount:=TreeAvail;
  TreeAvail:=P;
 End;

 Procedure DeleteRef(DRef:Integer);
 Begin
  If Tree^[DRef].NextCount=-1 Then LruAdd(DRef)
   Else Inc(Tree^[DRef].NextCount);
 End;

 Procedure BumpRef(BRef:Integer);
 Var
  F,P:Integer;
 Begin
  If Tree^[BRef].NextCount<0 Then Dec(Tree^[BRef].NextCount)
   Else Begin
   F:=Tree^[BRef].NextCount;
   P:=Tree^[BRef].Back;
   Tree^[P].NextCount:=F;
   Tree^[F].Back:=P;
   Tree^[BRef].NextCount:=-1;
  End;
 End;

 Procedure PutChars(X:Integer);
 Begin
  Stack^[0]:=0;
  While True do Begin
   While X>TerseCodeSize do Begin
    Inc(Stack^[0]);
    If Stack^[0]>TerseStackSize Then Begin
     WriteLn('Pile TERSE pleine.');
     Halt(1);
    End;
    Stack^[Stack^[0]]:=Tree^[X].Right;
    X:=Tree^[X].Left;
   End;
   If X<0 Then Begin
    WriteLn('Sequence TERSE invalide.');
    Halt(1);
   End;
   TersePutChar(X);
   If Stack^[0]>0 Then Begin
    X:=Stack^[Stack^[0]];
    Dec(Stack^[0]);
   End
    Else Break;
  End;
 End;

Var
 N,G,H:Integer;
Begin
 GetMem(Tree,SizeOf(TTerseTreeArray));
 GetMem(Stack,SizeOf(TTerseStackArray));
 If(Tree=NIL)or(Stack=NIL)Then Begin
  WriteLn('Memoire insuffisante pour TERSE SPACK.');
  Halt(1);
 End;
 TreeInit;
 Tree^[TerseTreeSize-1].NextCount:=TerseNone;
 H:=TerseGetBlok;
 If H<>TerseEOF Then Begin
  PutChars(H);
  G:=TerseGetBlok;
  While G<>TerseEOF do Begin
   If TreeAvail=TerseNone Then LruKill;
   PutChars(G);
   N:=GetTreeNode;
   Tree^[N].Left:=H;
   Tree^[N].Right:=G;
   BumpRef(H);
   BumpRef(G);
   LruAdd(N);
   H:=G;
   G:=TerseGetBlok;
  End;
 End;
 FreeMem(Tree,SizeOf(TTerseTreeArray));
 FreeMem(Stack,SizeOf(TTerseStackArray));
End;

Procedure InflateTerse;
Var
 Version,Byte2,Byte3,Byte4,VariableFlag,Flags,Ratio:Integer;
 RecordLen1,BlockSize:Integer;
 RecordLen2:LongInt;
 Spack:Boolean;
Begin
 InitWindow(False);
 TerseBitsAvailable:=0;
 TerseSavedBits:=0;
 Version:=TerseReadByte;
 Spack:=True;
 Case Version of
  $01,$07:Begin
    Byte2:=TerseReadByte;
    Byte3:=TerseReadByte;
    Byte4:=TerseReadByte;
    RecordLen1:=TerseReadWordBE;
    If(RecordLen1=0)Then Begin End;
    If(Byte2<>$89)or(Byte3<>$69)or(Byte4<>$A5)Then Begin
     WriteLn('En-tete TERSE invalide.');
     Halt(1);
    End;
    Spack:=False;
   End;
  $02,$05:Begin
    VariableFlag:=TerseReadByte;
    RecordLen1:=TerseReadWordBE;
    Flags:=TerseReadByte;
    Ratio:=TerseReadByte;
    BlockSize:=TerseReadWordBE;
    RecordLen2:=TerseReadDWordBE;
    If(VariableFlag<>0)and(VariableFlag<>1)Then Begin
     WriteLn('Format enregistrement TERSE invalide.');
     Halt(1);
    End;
    If(RecordLen1=0)and(RecordLen2=0)Then Begin
     WriteLn('Longueur enregistrement TERSE invalide.');
     Halt(1);
    End;
    If(Flags=0)and((Ratio<>0)or(BlockSize<>0))Then Begin
     WriteLn('En-tete TERSE invalide.');
     Halt(1);
    End;
    Spack:=Version=$05;
   End;
 Else
  WriteLn('Version TERSE non reconnue.');
  Halt(1);
 End;
 If Spack Then InflateTerseSpack
          Else InflateTersePack;
End;

Function ZstdReadByte:Byte;
Begin
 ZstdReadByte:=ReadCompByte;
End;

Function ZstdReadWordLE:LongInt;
Var
 B1,B2:LongInt;
Begin
 B1:=ZstdReadByte;
 B2:=ZstdReadByte;
 ZstdReadWordLE:=B1+256*B2;
End;

Function ZstdReadDWordLE:LongInt;
Var
 B1,B2,B3,B4:LongInt;
Begin
 B1:=ZstdReadByte;
 B2:=ZstdReadByte;
 B3:=ZstdReadByte;
 B4:=ZstdReadByte;
 ZstdReadDWordLE:=B1+256*B2+65536*B3+16777216*B4;
End;

Procedure ZstdSkip(N:LongInt);
Begin
 While N>0 do Begin
  ZstdReadByte;
  Dec(N);
 End;
End;

Function ZstdReadSize(SizeBytes:Integer;Add256:Boolean):LongInt;
Var
 I:Integer;
 V,Mult:LongInt;
Begin
 V:=0;
 Mult:=1;
 For I:=1 to SizeBytes do Begin
  V:=V+Mult*ZstdReadByte;
  Mult:=Mult*256;
 End;
 If Add256 Then Inc(V,256);
 ZstdReadSize:=V;
End;

Function ZstdBitsMask(N:Integer):LongInt;
Begin
 If N<=0 Then ZstdBitsMask:=0
  Else If N>=31 Then ZstdBitsMask:=$7FFFFFFF
  Else ZstdBitsMask:=(LongInt(1)shl N)-1;
End;

Function ZstdHighBit(V:Integer):Integer;
Var
 R:Integer;
Begin
 R:=0;
 While V>1 do Begin
  V:=V shr 1;
  Inc(R);
 End;
 ZstdHighBit:=R;
End;

Function ZstdBufGet(Buf:PZstdSeqBuffer;Index:LongInt):Byte;Forward;
Procedure ZstdBufSet(Buf:PZstdSeqBuffer;Index:LongInt;Value:Byte);Forward;
Procedure ZstdBufAlloc(Var Buf:PZstdSeqBuffer);Forward;
Procedure ZstdBufFree(Var Buf:PZstdSeqBuffer);Forward;

Function ZstdFSEReadNCount(Var NCount;MaxSymbol,MaxTableLog:Integer;
 Var TableLog:Integer;Var HeaderSize:Integer):Integer;
Type
 TNCount=Array[0..ZstdFSEMaxSymbols]of Integer;
Var
 Count:^TNCount;
 BitStream:LongInt;
 BitCount,ByteCount,CharNum,Remaining,Threshold,NBBits,MaxV,Value:Integer;
 Previous0:Boolean;
 B:Byte;

 Procedure NeedBits(N:Integer);
 Begin
  While BitCount<N do Begin
   B:=ZstdReadByte;
   BitStream:=BitStream or(LongInt(B)shl BitCount);
   Inc(BitCount,8);
   Inc(ByteCount);
  End;
 End;

Begin
 Count:=@NCount;
 For CharNum:=0 to ZstdFSEMaxSymbols do Count^[CharNum]:=0;
 B:=ZstdReadByte;
 BitStream:=B;
 BitCount:=8;
 ByteCount:=1;
 TableLog:=(B and 15)+5;
 If(TableLog<5)or(TableLog>MaxTableLog)Then Begin
  WriteLn('TableLog FSE Zstandard invalide.');
  Halt(1);
 End;
 BitStream:=BitStream shr 4;
 Dec(BitCount,4);
 Remaining:=(1 shl TableLog)+1;
 Threshold:=1 shl TableLog;
 NBBits:=TableLog+1;
 CharNum:=0;
 Previous0:=False;
 While(CharNum<=MaxSymbol)and(Remaining>1)do Begin
  If Previous0 Then Begin
   NeedBits(2);
   While(BitStream and 3)=3 do Begin
    Inc(CharNum,3);
    BitStream:=BitStream shr 2;
    Dec(BitCount,2);
    NeedBits(2);
   End;
   Inc(CharNum,Integer(BitStream and 3));
   BitStream:=BitStream shr 2;
   Dec(BitCount,2);
   If CharNum>MaxSymbol Then Begin
    WriteLn('RLE FSE Zstandard invalide.');
    Halt(1);
   End;
   Previous0:=False;
  End;
  MaxV:=(Threshold shl 1)-1-Remaining;
  NeedBits(NBBits);
  Value:=Integer(BitStream and(Threshold-1));
  If Value<MaxV Then Begin
   BitStream:=BitStream shr(NBBits-1);
   Dec(BitCount,NBBits-1);
  End
   Else
  Begin
   Value:=Integer(BitStream and((Threshold shl 1)-1));
   If Value>=Threshold Then Dec(Value,MaxV);
   BitStream:=BitStream shr NBBits;
   Dec(BitCount,NBBits);
  End;
  Dec(Value);
  Count^[CharNum]:=Value;
  If Value<0 Then Dec(Remaining)
             Else Dec(Remaining,Value);
  Previous0:=Value=0;
  Inc(CharNum);
  While(Threshold>Remaining)do Begin
   Dec(NBBits);
   Threshold:=Threshold shr 1;
  End;
 End;
 If Remaining<>1 Then Begin
  WriteLn('Distribution FSE Zstandard invalide.');
  Halt(1);
 End;
 HeaderSize:=ByteCount;
 ZstdFSEReadNCount:=CharNum-1;
End;

Function ZstdFSEReadNCountBuf(Buf:PZstdSeqBuffer;Size:LongInt;
 Var NCount;MaxSymbol,MaxTableLog:Integer;
 Var TableLog:Integer;Var HeaderSize:Integer):Integer;
Type
 TNCount=Array[0..ZstdFSEMaxSymbols]of Integer;
Var
 Count:^TNCount;
 BitStream:LongInt;
 BitCount,ByteCount,CharNum,Remaining,Threshold,NBBits,MaxV,Value:Integer;
 Previous0:Boolean;
 B:Byte;

 Function ReadB:Byte;
 Begin
  If ByteCount>=Size Then Begin
   WriteLn('En-tete FSE Zstandard tronque.');
   Halt(1);
  End;
  ReadB:=ZstdBufGet(Buf,ByteCount);
  Inc(ByteCount);
 End;

 Procedure NeedBits(N:Integer);
 Begin
  While BitCount<N do Begin
   B:=ReadB;
   BitStream:=BitStream or(LongInt(B)shl BitCount);
   Inc(BitCount,8);
  End;
 End;

Begin
 Count:=@NCount;
 For CharNum:=0 to ZstdFSEMaxSymbols do Count^[CharNum]:=0;
 ByteCount:=0;
 B:=ReadB;
 BitStream:=B;
 BitCount:=8;
 TableLog:=(B and 15)+5;
 If(TableLog<5)or(TableLog>MaxTableLog)Then Begin
  WriteLn('TableLog FSE Zstandard invalide.');
  Halt(1);
 End;
 BitStream:=BitStream shr 4;
 Dec(BitCount,4);
 Remaining:=(1 shl TableLog)+1;
 Threshold:=1 shl TableLog;
 NBBits:=TableLog+1;
 CharNum:=0;
 Previous0:=False;
 While(CharNum<=MaxSymbol)and(Remaining>1)do Begin
  If Previous0 Then Begin
   NeedBits(2);
   While(BitStream and 3)=3 do Begin
    Inc(CharNum,3);
    BitStream:=BitStream shr 2;
    Dec(BitCount,2);
    NeedBits(2);
   End;
   Inc(CharNum,Integer(BitStream and 3));
   BitStream:=BitStream shr 2;
   Dec(BitCount,2);
   If CharNum>MaxSymbol Then Begin
    WriteLn('RLE FSE Zstandard invalide.');
    Halt(1);
   End;
   Previous0:=False;
  End;
  MaxV:=(Threshold shl 1)-1-Remaining;
  NeedBits(NBBits);
  Value:=Integer(BitStream and(Threshold-1));
  If Value<MaxV Then Begin
   BitStream:=BitStream shr(NBBits-1);
   Dec(BitCount,NBBits-1);
  End
   Else
  Begin
   Value:=Integer(BitStream and((Threshold shl 1)-1));
   If Value>=Threshold Then Dec(Value,MaxV);
   BitStream:=BitStream shr NBBits;
   Dec(BitCount,NBBits);
  End;
  Dec(Value);
  Count^[CharNum]:=Value;
  If Value<0 Then Dec(Remaining)
             Else Dec(Remaining,Value);
  Previous0:=Value=0;
  Inc(CharNum);
  While(Threshold>Remaining)do Begin
   Dec(NBBits);
   Threshold:=Threshold shr 1;
  End;
 End;
 If Remaining<>1 Then Begin
  WriteLn('Distribution FSE Zstandard invalide.');
  Halt(1);
 End;
 HeaderSize:=ByteCount;
 ZstdFSEReadNCountBuf:=CharNum-1;
End;

Procedure ZstdFSEBuildTable(Var T:ZstdFSETable;Var NCount;MaxSymbol,TableLog:Integer);
Type
 TNCount=Array[0..ZstdFSEMaxSymbols]of Integer;
 TSymbols=Array[0..ZstdFSEMaxTableSize-1]of Integer;
 TNext=Array[0..ZstdFSEMaxSymbols]of Integer;
Var
 Count:^TNCount;
 TableSymbol:^TSymbols;
 SymbolNext:^TNext;
 TableSize,HighThreshold,TableMask,Step,Pos:Integer;
 Sym,I,N,NextState,NB:Integer;
Begin
 Count:=@NCount;
 GetMem(TableSymbol,SizeOf(TSymbols));
 GetMem(SymbolNext,SizeOf(TNext));
 If(TableSymbol=NIL)or(SymbolNext=NIL)Then Begin
  WriteLn('Memoire insuffisante pour table FSE Zstandard.');
  Halt(1);
 End;
 TableSize:=1 shl TableLog;
 T.TableLog:=TableLog;
 T.TableSize:=TableSize;
 T.FastMode:=True;
 HighThreshold:=TableSize-1;
 For Sym:=0 to MaxSymbol do Begin
  If Count^[Sym]=-1 Then Begin
   TableSymbol^[HighThreshold]:=Sym;
   Dec(HighThreshold);
   SymbolNext^[Sym]:=1;
  End
   Else Begin
   If Count^[Sym]>=TableSize div 2 Then T.FastMode:=False;
   SymbolNext^[Sym]:=Count^[Sym];
  End;
 End;
 TableMask:=TableSize-1;
 Step:=(TableSize shr 1)+(TableSize shr 3)+3;
 Pos:=0;
 For Sym:=0 to MaxSymbol do Begin
  N:=Count^[Sym];
  If N>0 Then For I:=1 to N do Begin
   TableSymbol^[Pos]:=Sym;
   Pos:=(Pos+Step)and TableMask;
   While Pos>HighThreshold do Pos:=(Pos+Step)and TableMask;
  End;
 End;
 If Pos<>0 Then Begin
  FreeMem(TableSymbol,SizeOf(TSymbols));
  FreeMem(SymbolNext,SizeOf(TNext));
  WriteLn('Construction FSE Zstandard invalide.');
  Halt(1);
 End;
 For I:=0 to TableSize-1 do Begin
  Sym:=TableSymbol^[I];
  NextState:=SymbolNext^[Sym];
  Inc(SymbolNext^[Sym]);
  NB:=TableLog-ZstdHighBit(NextState);
  T.Entry[I].Symbol:=Byte(Sym);
  T.Entry[I].Bits:=NB;
  T.Entry[I].NewState:=(NextState shl NB)-TableSize;
 End;
 FreeMem(TableSymbol,SizeOf(TSymbols));
 FreeMem(SymbolNext,SizeOf(TNext));
End;

Procedure ZstdFSESelfTest;
Var
 Count:Array[0..ZstdFSEMaxSymbols]of Integer;
 T:ZstdFSETable;
 I:Integer;
Begin
 For I:=0 to ZstdFSEMaxSymbols do Count[I]:=0;
 Count[0]:=1;
 Count[1]:=1;
 Count[2]:=1;
 Count[3]:=1;
 ZstdFSEBuildTable(T,Count,3,2);
 If(T.TableSize<>4)or(T.Entry[0].Bits>2)Then Begin
  WriteLn('Auto-test FSE Zstandard invalide.');
  Halt(1);
 End;
End;

Procedure ZstdHuffBuildTable(Var H:ZstdHuffTable;MaxSymbol:Integer);
Var
 Count:Array[0..ZstdHuffMaxBits]of Integer;
 Start:Array[0..ZstdHuffMaxBits]of Integer;
 Bits,Sym,Idx,TableLog,Sum,W,Next,Len,J:Integer;
Begin
 For Bits:=0 to ZstdHuffMaxBits do Count[Bits]:=0;
 Sum:=0;
 For Sym:=0 to MaxSymbol do Begin
  If H.Weight[Sym]>ZstdHuffMaxBits Then Begin
   WriteLn('Poids Huffman Zstandard invalide.');
   Halt(1);
  End;
  If H.Weight[Sym]>0 Then Inc(Sum,1 shl(H.Weight[Sym]-1));
 End;
 If Sum=0 Then Begin
  WriteLn('Table Huffman Zstandard vide.');
  Halt(1);
 End;
 TableLog:=ZstdHighBit(Sum);
 If(1 shl TableLog)<>Sum Then Begin
  WriteLn('Somme des poids Huffman Zstandard invalide.');
  Halt(1);
 End;
 If TableLog>11 Then Begin
  WriteLn('Table Huffman Zstandard trop grande.');
  Halt(1);
 End;
 H.TableLog:=TableLog;
 H.TableSize:=1 shl TableLog;
 H.MaxSymbol:=MaxSymbol;
 For Idx:=0 to ZstdHuffMaxTableSize-1 do Begin
  H.Entry[Idx].Symbol:=0;
  H.Entry[Idx].Bits:=0;
 End;
 For Sym:=0 to MaxSymbol do Begin
  W:=H.Weight[Sym];
  If W<>0 Then Inc(Count[W]);
 End;
 If(Count[1]<2)or((Count[1]and 1)<>0)Then Begin
  WriteLn('Poids Huffman Zstandard invalides.');
  Halt(1);
 End;
 Next:=0;
 For W:=1 to TableLog do Begin
  Start[W]:=Next;
  Inc(Next,Count[W]shl(W-1));
 End;
 For Sym:=0 to MaxSymbol do Begin
  W:=H.Weight[Sym];
  If W<>0 Then Begin
   Bits:=TableLog+1-W;
   If(Bits<1)or(Bits>ZstdHuffMaxBits)Then Begin
    WriteLn('Longueur Huffman Zstandard invalide.');
    Halt(1);
   End;
   Len:=1 shl(W-1);
   Idx:=Start[W];
   For J:=0 to Len-1 do Begin
    H.Entry[Idx].Symbol:=Byte(Sym);
    H.Entry[Idx].Bits:=Bits;
    Inc(Idx);
   End;
   Inc(Start[W],Len);
  End;
 End;
End;

Procedure ZstdHuffFinishWeights(Var H:ZstdHuffTable;NumWeights:Integer);
Var
 I,Sum,Full,Left,LastWeight,MaxSymbol:Integer;
Begin
 If(NumWeights<1)or(NumWeights>=ZstdHuffMaxSymbols)Then Begin
  WriteLn('Nombre de poids Huffman Zstandard invalide.');
  Halt(1);
 End;
 Sum:=0;
 For I:=0 to NumWeights-1 do Begin
  If H.Weight[I]>ZstdHuffMaxBits Then Begin
   WriteLn('Poids Huffman Zstandard invalide.');
   Halt(1);
  End;
  If H.Weight[I]<>0 Then Inc(Sum,1 shl(H.Weight[I]-1));
 End;
 If Sum=0 Then Begin
  WriteLn('Poids Huffman Zstandard vides.');
  Halt(1);
 End;
 Full:=1;
 While Full<Sum do Full:=Full shl 1;
 Left:=Full-Sum;
 If Left=0 Then Begin
  WriteLn('Poids final Huffman Zstandard invalide.');
  Halt(1);
 End;
 LastWeight:=0;
 While Left>1 do Begin
  If(Left and 1)<>0 Then Begin
   WriteLn('Poids final Huffman Zstandard invalide.');
   Halt(1);
  End;
  Left:=Left shr 1;
  Inc(LastWeight);
 End;
 Inc(LastWeight);
 H.Weight[NumWeights]:=LastWeight;
 MaxSymbol:=NumWeights;
 ZstdHuffBuildTable(H,MaxSymbol);
End;

Procedure ZstdHuffReadDirect(Var H:ZstdHuffTable;HeaderByte:Integer;
 Var HeaderSize:Integer);
Var
 NumWeights,I,B:Integer;
Begin
 NumWeights:=HeaderByte-127;
 If(NumWeights<1)or(NumWeights>ZstdHuffMaxSymbols-1)Then Begin
  WriteLn('En-tete Huffman Zstandard invalide.');
  Halt(1);
 End;
 For I:=0 to ZstdHuffMaxSymbols-1 do H.Weight[I]:=0;
 HeaderSize:=1+(NumWeights+1)div 2;
 For I:=0 to NumWeights-1 do Begin
  If(I and 1)=0 Then Begin
   B:=ZstdReadByte;
   H.Weight[I]:=(B shr 4)and 15;
   If I+1<NumWeights Then H.Weight[I+1]:=B and 15;
  End;
 End;
 ZstdHuffFinishWeights(H,NumWeights);
End;

Procedure ZstdHuffReadFSE(Var H:ZstdHuffTable;HeaderByte:Integer;
 Var HeaderSize:Integer);
Type
 TCount=Array[0..ZstdFSEMaxSymbols]of Integer;
Var
 Buf:PZstdSeqBuffer;
 Count:TCount;
 T:ZstdFSETable;
 TableLog,FSEHeaderSize,LastSym:Integer;
 I,State1,State2,NumWeights:Integer;
 Off,Start,Cnt:Integer;
 Bits:LongInt;

 Function RFetch(N:Integer):Boolean;
 Begin
  While Cnt<N do Begin
   If Off<=Start Then Begin
    RFetch:=False;
    Exit;
   End;
   Dec(Off);
   Bits:=(Bits shl 8)or ZstdBufGet(Buf,Off);
   Inc(Cnt,8);
  End;
  RFetch:=True;
 End;

 Function RVal(N:Integer):LongInt;
 Begin
  If N=0 Then Begin
   RVal:=0;
   Exit;
  End;
  If Not RFetch(N)Then Begin
   WriteLn('En-tete Huffman FSE Zstandard tronque.');
   Halt(1);
  End;
  Dec(Cnt,N);
  RVal:=UShiftRight(Bits,Cnt)and ZstdBitsMask(N);
 End;

 Procedure NextState(Var State:Integer);
 Var
  E:ZstdFSEEntry;
 Begin
  E:=T.Entry[State];
  State:=E.NewState+RVal(E.Bits);
 End;

Begin
 If(HeaderByte<=0)or(HeaderByte>127)Then Begin
  WriteLn('Taille en-tete Huffman FSE Zstandard invalide.');
  Halt(1);
 End;
 ZstdBufAlloc(Buf);
 If Buf=NIL Then Begin
  WriteLn('Memoire insuffisante pour en-tete Huffman Zstandard.');
  Halt(1);
 End;
 For I:=0 to HeaderByte-1 do ZstdBufSet(Buf,I,ZstdReadByte);
 LastSym:=ZstdFSEReadNCountBuf(Buf,HeaderByte,Count,255,6,
  TableLog,FSEHeaderSize);
 If LastSym>255 Then Begin
  ZstdBufFree(Buf);
  WriteLn('Table FSE Huffman Zstandard invalide.');
  Halt(1);
 End;
 ZstdFSEBuildTable(T,Count,LastSym,TableLog);
 If FSEHeaderSize>=HeaderByte Then Begin
  ZstdBufFree(Buf);
  WriteLn('Bitstream Huffman FSE Zstandard absent.');
  Halt(1);
 End;
 Start:=FSEHeaderSize;
 Off:=HeaderByte-1;
 Bits:=ZstdBufGet(Buf,Off);
 If Bits=0 Then Begin
  ZstdBufFree(Buf);
  WriteLn('Fin bitstream Huffman FSE Zstandard invalide.');
  Halt(1);
 End;
 Cnt:=ZstdHighBit(Integer(Bits));
 State1:=Integer(RVal(TableLog));
 State2:=Integer(RVal(TableLog));
 For I:=0 to ZstdHuffMaxSymbols-1 do H.Weight[I]:=0;
 NumWeights:=0;
 While True do Begin
  If Not RFetch(T.Entry[State1].Bits)Then Begin
   If NumWeights>=254 Then Begin
    ZstdBufFree(Buf);
    WriteLn('Trop de poids Huffman Zstandard.');
    Halt(1);
   End;
   H.Weight[NumWeights]:=T.Entry[State1].Symbol;
   H.Weight[NumWeights+1]:=T.Entry[State2].Symbol;
   Inc(NumWeights,2);
   Break;
  End;
  If NumWeights>=255 Then Begin
   ZstdBufFree(Buf);
   WriteLn('Trop de poids Huffman Zstandard.');
   Halt(1);
  End;
  H.Weight[NumWeights]:=T.Entry[State1].Symbol;
  Inc(NumWeights);
  NextState(State1);
  If Not RFetch(T.Entry[State2].Bits)Then Begin
   If NumWeights>=254 Then Begin
    ZstdBufFree(Buf);
    WriteLn('Trop de poids Huffman Zstandard.');
    Halt(1);
   End;
   H.Weight[NumWeights]:=T.Entry[State2].Symbol;
   H.Weight[NumWeights+1]:=T.Entry[State1].Symbol;
   Inc(NumWeights,2);
   Break;
  End;
  If NumWeights>=255 Then Begin
   ZstdBufFree(Buf);
   WriteLn('Trop de poids Huffman Zstandard.');
   Halt(1);
  End;
  H.Weight[NumWeights]:=T.Entry[State2].Symbol;
  Inc(NumWeights);
  NextState(State2);
 End;
 ZstdBufFree(Buf);
 HeaderSize:=1+HeaderByte;
 ZstdHuffFinishWeights(H,NumWeights);
End;

Procedure ZstdHuffReadTable(Var H:ZstdHuffTable;Var HeaderSize:Integer);
Var
 HeaderByte:Integer;
Begin
 HeaderByte:=ZstdReadByte;
 If HeaderByte>=128 Then ZstdHuffReadDirect(H,HeaderByte,HeaderSize)
  Else ZstdHuffReadFSE(H,HeaderByte,HeaderSize);
End;

Procedure ZstdHuffSelfTest;
Var
 H:ZstdHuffTable;
 I:Integer;
Begin
 For I:=0 to ZstdHuffMaxSymbols-1 do H.Weight[I]:=0;
 H.Weight[Ord('A')]:=1;
 H.Weight[Ord('B')]:=1;
 ZstdHuffBuildTable(H,Ord('B'));
 If(H.TableSize<>2)or(H.Entry[0].Bits=0)or(H.Entry[1].Bits=0)Then Begin
  WriteLn('Auto-test Huffman Zstandard invalide.');
  Halt(1);
 End;
End;

Procedure ZstdBuildDefaultSeqTables(Var S:ZstdSeqTables);
Const
 LLDef:Array[0..35]of Integer=(
  4,3,2,2,2,2,2,2,2,2,2,2,2,1,1,1,
  2,2,2,2,2,2,2,2,2,3,2,1,1,1,1,1,
  -1,-1,-1,-1);
 MLDef:Array[0..52]of Integer=(
  1,4,3,2,2,2,2,2,2,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,-1,-1,
  -1,-1,-1,-1,-1);
 OFDef:Array[0..28]of Integer=(
  1,1,1,1,1,1,2,2,2,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,-1,-1,-1,-1,-1);
Begin
 ZstdFSEBuildTable(S.LL,LLDef,35,6);
 ZstdFSEBuildTable(S.ML,MLDef,52,6);
 ZstdFSEBuildTable(S.OFs,OFDef,28,5);
 S.LLValid:=True;
 S.MLValid:=True;
 S.OFValid:=True;
 S.LLMode:=0;
 S.MLMode:=0;
 S.OFMode:=0;
End;

Function ZstdSeqReadNumber:LongInt;
Var
 B0,B1,B2:Integer;
Begin
 B0:=ZstdReadByte;
 If B0=0 Then ZstdSeqReadNumber:=0
  Else If B0<128 Then ZstdSeqReadNumber:=B0
  Else If B0<255 Then Begin
   B1:=ZstdReadByte;
   ZstdSeqReadNumber:=((B0-128)shl 8)+B1;
  End
  Else Begin
   B1:=ZstdReadByte;
   B2:=ZstdReadByte;
   ZstdSeqReadNumber:=B1+(B2 shl 8)+$7F00;
  End;
End;

Procedure ZstdSeqReadOneTable(Var Tab:ZstdFSETable;Var Mode:Integer;
 Var RLE:Byte;Var Valid:Boolean;MaxSymbol,MaxLog:Integer;Name:String);
Var
 Count:Array[0..ZstdFSEMaxSymbols]of Integer;
 TableLog,HeaderSize,LastSym:Integer;
Begin
 Case Mode of
  0:Begin
     { Default tables are installed before this routine is used. }
     Valid:=True;
    End;
  1:Begin
     RLE:=ZstdReadByte;
     Valid:=True;
    End;
  2:Begin
     LastSym:=ZstdFSEReadNCount(Count,MaxSymbol,MaxLog,TableLog,HeaderSize);
     If LastSym>MaxSymbol Then Begin
      WriteLn('Table FSE ',Name,' Zstandard invalide.');
      Halt(1);
     End;
     ZstdFSEBuildTable(Tab,Count,LastSym,TableLog);
     Valid:=True;
    End;
  3:Begin
     If Not Valid Then Begin
      WriteLn('Repeat_Mode FSE ',Name,' Zstandard sans table precedente.');
      Halt(1);
     End;
    End;
 Else
  WriteLn('Mode FSE ',Name,' Zstandard invalide.');
  Halt(1);
 End;
End;

Function ZstdBufGet(Buf:PZstdSeqBuffer;Index:LongInt):Byte;
Begin
 ZstdBufGet:=Buf^.Chunks[Index shr ZstdSeqChunkBits]^[Index and ZstdSeqChunkMask];
End;

Procedure ZstdBufSet(Buf:PZstdSeqBuffer;Index:LongInt;Value:Byte);
Begin
 Buf^.Chunks[Index shr ZstdSeqChunkBits]^[Index and ZstdSeqChunkMask]:=Value;
End;

Procedure ZstdBufAlloc(Var Buf:PZstdSeqBuffer);
Var
 I,J:Integer;
Begin
 New(Buf);
 If Buf=NIL Then Exit;
 For I:=0 to ZstdSeqNumChunks-1 do Buf^.Chunks[I]:=NIL;
 For I:=0 to ZstdSeqNumChunks-1 do Begin
  New(Buf^.Chunks[I]);
  If Buf^.Chunks[I]=NIL Then Begin
   For J:=0 to I-1 do Dispose(Buf^.Chunks[J]);
   Dispose(Buf);
   Buf:=NIL;
   Exit;
  End;
 End;
End;

Procedure ZstdBufFree(Var Buf:PZstdSeqBuffer);
Var
 I:Integer;
Begin
 If Buf=NIL Then Exit;
 For I:=0 to ZstdSeqNumChunks-1 do
  If Buf^.Chunks[I]<>NIL Then Dispose(Buf^.Chunks[I]);
 Dispose(Buf);
 Buf:=NIL;
End;

Function ZstdByteHighBit(V:Byte):Integer;
Var
 I:Integer;
Begin
 For I:=7 downto 0 do
  If(V and(1 shl I))<>0 Then Begin
   ZstdByteHighBit:=I;
   Exit;
  End;
 ZstdByteHighBit:=-1;
End;

Procedure ZstdRevReload(Var B:ZstdRevBitStream);
Var
 NB,I,Shift:LongInt;
Begin
 If B.BitCount>32 Then Begin
  WriteLn('Bitstream sequences Zstandard trop court.');
  Halt(1);
 End;
 If B.Pos>=B.Base+4 Then Begin
  B.Pos:=B.Pos-(B.BitCount div 8);
  B.BitCount:=B.BitCount and 7;
 End
  Else If B.Pos<>B.Base Then Begin
  NB:=B.BitCount div 8;
  If B.Pos-NB<B.Base Then NB:=B.Pos-B.Base;
  B.Pos:=B.Pos-NB;
  B.BitCount:=B.BitCount-(NB*8);
 End;
 B.Bits:=0;
 Shift:=0;
 For I:=B.Pos to B.Pos+3 do Begin
  If I<B.Base+B.Size Then B.Bits:=B.Bits or(LongInt(ZstdBufGet(B.Buf,I))shl Shift);
  Inc(Shift,8);
 End;
End;

Procedure ZstdRevInit(Var B:ZstdRevBitStream;Buf:PZstdSeqBuffer;Base,Size:LongInt);
Var
 Last:Byte;
 I,Shift:LongInt;
Begin
 If Size<=0 Then Begin
  WriteLn('Bitstream sequences Zstandard vide.');
  Halt(1);
 End;
 B.Buf:=Buf;
 B.Base:=Base;
 B.Size:=Size;
 Last:=ZstdBufGet(Buf,Base+Size-1);
 If Last=0 Then Begin
  WriteLn('Fin de bitstream Zstandard invalide.');
  Halt(1);
 End;
 If Size>=4 Then B.Pos:=Base+Size-4
            Else B.Pos:=Base;
 B.Bits:=0;
 Shift:=0;
 For I:=B.Pos to B.Pos+3 do Begin
  If I<Base+Size Then B.Bits:=B.Bits or(LongInt(ZstdBufGet(Buf,I))shl Shift);
  Inc(Shift,8);
 End;
 B.BitCount:=8-ZstdByteHighBit(Last);
 If Size<4 Then B.BitCount:=B.BitCount+(4-Size)*8;
End;

Function ZstdRevReadBits(Var B:ZstdRevBitStream;N:Integer):LongInt;
Var
 R,T:LongInt;
Begin
 If N=0 Then Begin
  ZstdRevReadBits:=0;
  Exit;
 End;
 If B.BitCount+N>32 Then Begin
  ZstdRevReload(B);
  If B.BitCount+N>32 Then Begin
   WriteLn('Bitstream sequences Zstandard trop court.');
   Halt(1);
  End;
 End;
 T:=B.Bits shl B.BitCount;
 R:=UShiftRight(T,32-N)and ZstdBitsMask(N);
 Inc(B.BitCount,N);
 If B.BitCount>=25 Then ZstdRevReload(B);
 ZstdRevReadBits:=R;
End;

Function ZstdPeekBits(Var B:ZstdRevBitStream;N:Integer):LongInt;
Var
 T:LongInt;
Begin
 If N=0 Then Begin
  ZstdPeekBits:=0;
  Exit;
 End;
 If B.BitCount+N>32 Then Begin
  ZstdRevReload(B);
  If B.BitCount+N>32 Then Begin
   WriteLn('Bitstream Huffman Zstandard trop court.');
   Halt(1);
  End;
 End;
 T:=B.Bits shl B.BitCount;
 ZstdPeekBits:=UShiftRight(T,32-N)and ZstdBitsMask(N);
End;

Procedure ZstdConsumeBits(Var B:ZstdRevBitStream;N:Integer);
Begin
 Inc(B.BitCount,N);
 If B.BitCount>=25 Then ZstdRevReload(B);
End;

Procedure ZstdHuffDecodeStream(Var H:ZstdHuffTable;StreamBuf:PZstdSeqBuffer;
 StreamBase,StreamSize:LongInt;LitBuf:PZstdSeqBuffer;Var LitPos:LongInt;
 NumLits:LongInt);
Var
 Off,Start,Cnt:LongInt;
 Bits,Idx:LongInt;
 I:LongInt;

 Function HFetch(N:Integer):Boolean;
 Begin
  While Cnt<N do Begin
   If Off<=Start Then Begin
    HFetch:=False;
    Exit;
   End;
   Dec(Off);
   Bits:=(Bits shl 8)or ZstdBufGet(StreamBuf,Off);
   Inc(Cnt,8);
  End;
  HFetch:=True;
 End;
Begin
 If NumLits<=0 Then Exit;
 If StreamSize<=0 Then Begin
  WriteLn('Bitstream Huffman Zstandard vide.');
  Halt(1);
 End;
 Off:=StreamBase+StreamSize-1;
 If StreamBase>0 Then Start:=StreamBase-1
                 Else Start:=StreamBase;
 Bits:=ZstdBufGet(StreamBuf,Off);
 If Bits=0 Then Begin
  WriteLn('Fin bitstream Huffman Zstandard invalide.');
  Halt(1);
 End;
 Cnt:=ZstdHighBit(Integer(Bits));
 For I:=1 to NumLits do Begin
  If Not HFetch(H.TableLog)Then Begin
   WriteLn('Bitstream Huffman Zstandard trop court.');
   Halt(1);
  End;
  Idx:=UShiftRight(Bits,Cnt-H.TableLog)and ZstdBitsMask(H.TableLog);
  ZstdBufSet(LitBuf,LitPos,H.Entry[Idx].Symbol);
  Inc(LitPos);
  Dec(Cnt,H.Entry[Idx].Bits);
 End;
End;

Function ZstdFSESymbol(Var T:ZstdFSETable;State:Integer):Byte;
Begin
 If(State<0)or(State>=T.TableSize)Then Begin
  WriteLn('Etat FSE Zstandard invalide.');
  Halt(1);
 End;
 ZstdFSESymbol:=T.Entry[State].Symbol;
End;

Procedure ZstdFSENextState(Var BS:ZstdRevBitStream;Var T:ZstdFSETable;
 Var State:Integer);
Var
 E:ZstdFSEEntry;
Begin
 E:=T.Entry[State];
 State:=E.NewState+ZstdRevReadBits(BS,E.Bits);
End;

Procedure ZstdLLCode(Code:Byte;Var Base:LongInt;Var Bits:Integer);
Const
 BaseTab:Array[16..35]of LongInt=(
  16,18,20,22,24,28,32,40,48,64,128,256,512,1024,
  2048,4096,8192,16384,32768,65536);
 BitsTab:Array[16..35]of Byte=(
  1,1,1,1,2,2,3,3,4,6,7,8,9,10,11,12,13,14,15,16);
Begin
 If Code<=15 Then Begin
  Base:=Code;
  Bits:=0;
 End
  Else If Code<=35 Then Begin
  Base:=BaseTab[Code];
  Bits:=BitsTab[Code];
 End
  Else
 Begin
  WriteLn('Code LL Zstandard invalide.');
  Halt(1);
 End;
End;

Procedure ZstdMLCode(Code:Byte;Var Base:LongInt;Var Bits:Integer);
Const
 BaseTab:Array[32..52]of LongInt=(
  35,37,39,41,43,47,51,59,67,83,99,131,259,515,
  1027,2051,4099,8195,16387,32771,65539);
 BitsTab:Array[32..52]of Byte=(
  1,1,1,1,2,2,3,3,4,4,5,7,8,9,10,11,12,13,14,15,16);
Begin
 If Code<=31 Then Begin
  Base:=Code+3;
  Bits:=0;
 End
  Else If Code<=52 Then Begin
  Base:=BaseTab[Code];
  Bits:=BitsTab[Code];
 End
  Else
 Begin
  WriteLn('Code ML Zstandard invalide.');
  Halt(1);
 End;
End;

Function ZstdResolveOffset(OffsetValue,LL:LongInt):LongInt;
Var
 Offset:LongInt;
Begin
 If OffsetValue>3 Then Begin
  Offset:=OffsetValue-3;
  ZstdRep3:=ZstdRep2;
  ZstdRep2:=ZstdRep1;
  ZstdRep1:=Offset;
 End
  Else If OffsetValue=1 Then Begin
  If LL=0 Then Begin
   Offset:=ZstdRep2;
   ZstdRep2:=ZstdRep1;
   ZstdRep1:=Offset;
  End
   Else Offset:=ZstdRep1;
 End
  Else If OffsetValue=2 Then Begin
  Offset:=ZstdRep2;
  ZstdRep2:=ZstdRep1;
  ZstdRep1:=Offset;
 End
  Else If OffsetValue=3 Then Begin
  If LL=0 Then Begin
   Offset:=ZstdRep1-1;
   ZstdRep3:=ZstdRep2;
   ZstdRep2:=ZstdRep1;
   ZstdRep1:=Offset;
  End
   Else Begin
   Offset:=ZstdRep3;
   ZstdRep3:=ZstdRep2;
   ZstdRep2:=ZstdRep1;
   ZstdRep1:=Offset;
  End;
 End
  Else
 Begin
  WriteLn('Offset Zstandard invalide.');
  Halt(1);
 End;
 If Offset<=0 Then Begin
  WriteLn('Repeat offset Zstandard invalide.');
  Halt(1);
 End;
 ZstdResolveOffset:=Offset;
End;

Procedure ZstdCopyMatch(Offset,ML:LongInt);
Var
 I:LongInt;
 B:Byte;
Begin
 If Offset>OutSize Then Begin
  WriteLn('Reference LZ77 Zstandard invalide.');
  Halt(1);
 End;
 For I:=1 to ML do Begin
  B:=GetWindowByte(WinPos-Offset);
  PutOutByte(B);
 End;
End;

Procedure ZstdExecuteSequence(LL,OffsetValue,ML:LongInt;
 LitBuf:PZstdSeqBuffer;Var LitPos:LongInt;LitSize:LongInt);
Var
 I,Offset:LongInt;
Begin
 If LitBuf=NIL Then Exit;
 If LitPos+LL>LitSize Then Begin
  WriteLn('Litteraux Zstandard insuffisants.');
  Halt(1);
 End;
 For I:=1 to LL do Begin
  PutOutByte(ZstdBufGet(LitBuf,LitPos));
  Inc(LitPos);
 End;
 Offset:=ZstdResolveOffset(OffsetValue,LL);
 ZstdCopyMatch(Offset,ML);
End;

Procedure ZstdSeqDecodeCodes(Var S:ZstdSeqTables;Buf:PZstdSeqBuffer;
 Size,NumSeq:LongInt;LitBuf:PZstdSeqBuffer;LitSize:LongInt;DoExecute:Boolean);
Var
 BS:ZstdRevBitStream;
 LLState,OFState,MLState:Integer;
 I,LL,ML,OffsetValue,LitPos:LongInt;
 Base:LongInt;
 ExtraBits:Integer;
 LLC,OMC,MLC:Byte;
Begin
 If NumSeq=0 Then Exit;
 ZstdRevInit(BS,Buf,0,Size);
 If S.LLMode=1 Then LLState:=0 Else LLState:=ZstdRevReadBits(BS,S.LL.TableLog);
 If S.OFMode=1 Then OFState:=0 Else OFState:=ZstdRevReadBits(BS,S.OFs.TableLog);
 If S.MLMode=1 Then MLState:=0 Else MLState:=ZstdRevReadBits(BS,S.ML.TableLog);
 LitPos:=0;
 For I:=1 to NumSeq do Begin
  If S.LLMode=1 Then LLC:=S.LLRLE Else LLC:=ZstdFSESymbol(S.LL,LLState);
  If S.OFMode=1 Then OMC:=S.OFRLE Else OMC:=ZstdFSESymbol(S.OFs,OFState);
  If S.MLMode=1 Then MLC:=S.MLRLE Else MLC:=ZstdFSESymbol(S.ML,MLState);
  If OMC>30 Then Begin
   WriteLn('Code offset Zstandard trop grand.');
   Halt(1);
  End;
  OffsetValue:=(LongInt(1)shl OMC)+ZstdRevReadBits(BS,OMC);
  ZstdMLCode(MLC,Base,ExtraBits);
  ML:=Base+ZstdRevReadBits(BS,ExtraBits);
  ZstdLLCode(LLC,Base,ExtraBits);
  LL:=Base+ZstdRevReadBits(BS,ExtraBits);
  If DoExecute Then ZstdExecuteSequence(LL,OffsetValue,ML,LitBuf,LitPos,LitSize)
               Else ZstdResolveOffset(OffsetValue,LL);
  If I<NumSeq Then Begin
   If S.LLMode<>1 Then ZstdFSENextState(BS,S.LL,LLState);
   If S.MLMode<>1 Then ZstdFSENextState(BS,S.ML,MLState);
   If S.OFMode<>1 Then ZstdFSENextState(BS,S.OFs,OFState);
  End;
 End;
 If DoExecute and(LitBuf<>NIL)Then Begin
  While LitPos<LitSize do Begin
   PutOutByte(ZstdBufGet(LitBuf,LitPos));
   Inc(LitPos);
  End;
 End;
End;

Procedure ZstdReadLiteralsSection(LitBuf:PZstdSeqBuffer;Var LitSize:LongInt;
 Var H:ZstdHuffTable;Var HValid:Boolean;Var BytesRead:LongInt);
Var
 H0,H1,H2,H3,H4:Integer;
 LitType,SizeFormat,NumStreams,HeaderSize:Integer;
 RegenSize,CompSize,Bytes,StartCount:LongInt;
 LitPos,I:LongInt;
 RleByte:Byte;
 StreamBuf:PZstdSeqBuffer;
 J1,J2,J3:Integer;
 Sz1,Sz2,Sz3,Sz4:LongInt;
 Off1,Off2,Off3,Off4:LongInt;
 Seg:LongInt;
Begin
 StartCount:=CompLeft;
 H0:=ZstdReadByte;
 LitType:=H0 and 3;
 SizeFormat:=(H0 shr 2)and 3;
 If(LitType=0)or(LitType=1)Then Begin
  Case SizeFormat of
   0,2:RegenSize:=H0 shr 3;
   1:Begin
      H1:=ZstdReadByte;
      RegenSize:=LongInt(H0 shr 4)or(LongInt(H1)shl 4);
     End;
   3:Begin
      H1:=ZstdReadByte;
      H2:=ZstdReadByte;
      RegenSize:=LongInt(H0 shr 4)or(LongInt(H1)shl 4)or(LongInt(H2)shl 12);
     End;
  End;
  If RegenSize>ZstdSeqMaxBlockSize Then Begin
   WriteLn('Litteraux Zstandard trop volumineux.');
   Halt(1);
  End;
  LitSize:=RegenSize;
  If LitType=0 Then Begin
   For I:=0 to RegenSize-1 do ZstdBufSet(LitBuf,I,ZstdReadByte);
  End
   Else
  Begin
   RleByte:=ZstdReadByte;
   For I:=0 to RegenSize-1 do ZstdBufSet(LitBuf,I,RleByte);
  End;
  BytesRead:=StartCount-CompLeft;
  Exit;
 End;
 { LitType in [2,3]: compressed/treeless Huffman }
 Case SizeFormat of
  0:Begin
     NumStreams:=1;
     H1:=ZstdReadByte;
     H2:=ZstdReadByte;
     RegenSize:=LongInt(H0 shr 4)or(LongInt(H1 and $3F)shl 4);
     CompSize:=LongInt(H1 shr 6)or(LongInt(H2)shl 2);
    End;
  1:Begin
     NumStreams:=4;
     H1:=ZstdReadByte;
     H2:=ZstdReadByte;
     RegenSize:=LongInt(H0 shr 4)or(LongInt(H1 and $3F)shl 4);
     CompSize:=LongInt(H1 shr 6)or(LongInt(H2)shl 2);
    End;
  2:Begin
     NumStreams:=4;
     H1:=ZstdReadByte;
     H2:=ZstdReadByte;
     H3:=ZstdReadByte;
     RegenSize:=LongInt(H0 shr 4)or(LongInt(H1)shl 4)or(LongInt(H2 and $3)shl 12);
     CompSize:=LongInt(H2 shr 2)or(LongInt(H3)shl 6);
    End;
  3:Begin
     NumStreams:=4;
     H1:=ZstdReadByte;
     H2:=ZstdReadByte;
     H3:=ZstdReadByte;
     H4:=ZstdReadByte;
     RegenSize:=LongInt(H0 shr 4)or(LongInt(H1)shl 4)or(LongInt(H2 and $3F)shl 12);
     CompSize:=LongInt(H2 shr 6)or(LongInt(H3)shl 2)or(LongInt(H4)shl 10);
    End;
 End;
 If RegenSize>ZstdSeqMaxBlockSize Then Begin
  WriteLn('Litteraux Zstandard trop volumineux.');
  Halt(1);
 End;
 If CompSize>ZstdSeqMaxBlockSize Then Begin
  WriteLn('Flux litteraux Zstandard trop volumineux.');
  Halt(1);
 End;
 LitSize:=RegenSize;
 If LitType=2 Then Begin
  ZstdHuffReadTable(H,HeaderSize);
  HValid:=True;
  Bytes:=CompSize-HeaderSize;
 End
  Else
 Begin
  If Not HValid Then Begin
   WriteLn('Litteraux treeless Zstandard sans table Huffman.');
   Halt(1);
  End;
  Bytes:=CompSize;
 End;
 If Bytes<=0 Then Begin
  WriteLn('Taille flux Huffman Zstandard invalide.');
  Halt(1);
 End;
 ZstdBufAlloc(StreamBuf);
 If StreamBuf=NIL Then Begin
  WriteLn('Memoire insuffisante pour litteraux Zstandard.');
  Halt(1);
 End;
 LitPos:=0;
 If NumStreams=1 Then Begin
  For I:=0 to Bytes-1 do ZstdBufSet(StreamBuf,I,ZstdReadByte);
  ZstdHuffDecodeStream(H,StreamBuf,0,Bytes,LitBuf,LitPos,RegenSize);
 End
  Else
 Begin
  If Bytes<6 Then Begin
   WriteLn('Table de saut Huffman Zstandard invalide.');
   ZstdBufFree(StreamBuf);
   Halt(1);
  End;
  J1:=ZstdReadByte;J1:=J1 or(Integer(ZstdReadByte)shl 8);
  J2:=ZstdReadByte;J2:=J2 or(Integer(ZstdReadByte)shl 8);
  J3:=ZstdReadByte;J3:=J3 or(Integer(ZstdReadByte)shl 8);
  Sz1:=J1;Sz2:=J2;Sz3:=J3;
  Sz4:=Bytes-6-Sz1-Sz2-Sz3;
  If Sz4<=0 Then Begin
   WriteLn('Taille flux 4 Huffman Zstandard invalide.');
   ZstdBufFree(StreamBuf);
   Halt(1);
  End;
  ZstdBufSet(StreamBuf,0,Byte(J1 and $FF));
  ZstdBufSet(StreamBuf,1,Byte((J1 shr 8)and $FF));
  ZstdBufSet(StreamBuf,2,Byte(J2 and $FF));
  ZstdBufSet(StreamBuf,3,Byte((J2 shr 8)and $FF));
  ZstdBufSet(StreamBuf,4,Byte(J3 and $FF));
  ZstdBufSet(StreamBuf,5,Byte((J3 shr 8)and $FF));
  Off1:=6;Off2:=Off1+Sz1;Off3:=Off2+Sz2;Off4:=Off3+Sz3;
  For I:=6 to Bytes-1 do ZstdBufSet(StreamBuf,I,ZstdReadByte);
  Seg:=(RegenSize+3)div 4;
  ZstdHuffDecodeStream(H,StreamBuf,Off1,Sz1,LitBuf,LitPos,Seg);
  ZstdHuffDecodeStream(H,StreamBuf,Off2,Sz2,LitBuf,LitPos,Seg);
  ZstdHuffDecodeStream(H,StreamBuf,Off3,Sz3,LitBuf,LitPos,Seg);
  ZstdHuffDecodeStream(H,StreamBuf,Off4,Sz4,LitBuf,LitPos,RegenSize-3*Seg);
 End;
 ZstdBufFree(StreamBuf);
 If LitPos<>RegenSize Then Begin
  WriteLn('Decodage litteraux Zstandard incomplet.');
  Halt(1);
 End;
 BytesRead:=StartCount-CompLeft;
End;

Procedure ZstdReadSequencesAndExecute(BlockSize,LitConsumed:LongInt;
 Var S:ZstdSeqTables;LitBuf:PZstdSeqBuffer;LitSize:LongInt);
Var
 NumSeq,BitstreamSize,I,LitPos:LongInt;
 StartCount,HdrConsumed:LongInt;
 Modes:Integer;
 Buf:PZstdSeqBuffer;
Begin
 StartCount:=CompLeft;
 NumSeq:=ZstdSeqReadNumber;
 If NumSeq=0 Then Begin
  LitPos:=0;
  While LitPos<LitSize do Begin
   PutOutByte(ZstdBufGet(LitBuf,LitPos));
   Inc(LitPos);
  End;
  HdrConsumed:=StartCount-CompLeft;
  If LitConsumed+HdrConsumed<>BlockSize Then Begin
   WriteLn('Taille bloc Zstandard incoherente.');
   Halt(1);
  End;
  Exit;
 End;
 Modes:=ZstdReadByte;
 If(Modes and 3)<>0 Then Begin
  WriteLn('Modes sequences Zstandard invalides.');
  Halt(1);
 End;
 S.LLMode:=(Modes shr 6)and 3;
 S.OFMode:=(Modes shr 4)and 3;
 S.MLMode:=(Modes shr 2)and 3;
 ZstdSeqReadOneTable(S.LL,S.LLMode,S.LLRLE,S.LLValid,35,9,'LL');
 ZstdSeqReadOneTable(S.OFs,S.OFMode,S.OFRLE,S.OFValid,31,8,'OF');
 ZstdSeqReadOneTable(S.ML,S.MLMode,S.MLRLE,S.MLValid,52,9,'ML');
 HdrConsumed:=StartCount-CompLeft;
 BitstreamSize:=BlockSize-LitConsumed-HdrConsumed;
 If(BitstreamSize<=0)or(BitstreamSize>ZstdSeqMaxBlockSize)Then Begin
  WriteLn('Taille bitstream sequences Zstandard invalide.');
  Halt(1);
 End;
 ZstdBufAlloc(Buf);
 If Buf=NIL Then Begin
  WriteLn('Memoire insuffisante pour sequences Zstandard.');
  Halt(1);
 End;
 For I:=0 to BitstreamSize-1 do ZstdBufSet(Buf,I,ZstdReadByte);
 ZstdSeqDecodeCodes(S,Buf,BitstreamSize,NumSeq,LitBuf,LitSize,True);
 ZstdBufFree(Buf);
End;

Procedure InflateZstdFrame;
Var
 Desc,DictFlag,FCSFlag,BlockType:Integer;
 Header:LongInt;
 SingleSegment,ChecksumFlag,LastBlock:Boolean;
 DictSize,FCSSize:Integer;
 BlockSize,I,LitSize,LitConsumed:LongInt;
 B:Byte;
 LitBuf:PZstdSeqBuffer;
 Huff:ZstdHuffTable;
 HuffValid:Boolean;
 Seq:ZstdSeqTables;
Begin
 ZstdRep1:=1;
 ZstdRep2:=4;
 ZstdRep3:=8;
 HuffValid:=False;
 ZstdBuildDefaultSeqTables(Seq);
 ZstdBufAlloc(LitBuf);
 If LitBuf=NIL Then Begin
  WriteLn('Memoire insuffisante pour bloc Zstandard.');
  Halt(1);
 End;
 Desc:=ZstdReadByte;
 DictFlag:=Desc and 3;
 ChecksumFlag:=(Desc and 4)<>0;
 If(Desc and 8)<>0 Then Begin
  WriteLn('En-tete Zstandard reserve invalide.');
  Halt(1);
 End;
 SingleSegment:=(Desc and 32)<>0;
 FCSFlag:=(Desc shr 6)and 3;
 If Not SingleSegment Then ZstdReadByte;
 Case DictFlag of
  0:DictSize:=0;
  1:DictSize:=1;
  2:DictSize:=2;
  3:DictSize:=4;
 Else
  DictSize:=0;
 End;
 ZstdSkip(DictSize);
 If FCSFlag=0 Then Begin
  If SingleSegment Then FCSSize:=1 Else FCSSize:=0;
 End
  Else If FCSFlag=1 Then FCSSize:=2
  Else If FCSFlag=2 Then FCSSize:=4
  Else FCSSize:=8;
 If FCSSize=2 Then ZstdReadSize(FCSSize,True)
              Else ZstdReadSize(FCSSize,False);
 Repeat
  Header:=ZstdReadByte;
  Header:=Header or(Integer(ZstdReadByte)shl 8);
  Header:=Header or(Integer(ZstdReadByte)shl 16);
  LastBlock:=(Header and 1)<>0;
  BlockType:=(Header shr 1)and 3;
  BlockSize:=Header shr 3;
  Case BlockType of
   0:Begin
      For I:=1 to BlockSize do PutOutByte(ZstdReadByte);
     End;
   1:Begin
      B:=ZstdReadByte;
      For I:=1 to BlockSize do PutOutByte(B);
     End;
   2:Begin
      LitSize:=0;
      LitConsumed:=0;
      ZstdReadLiteralsSection(LitBuf,LitSize,Huff,HuffValid,LitConsumed);
      ZstdReadSequencesAndExecute(BlockSize,LitConsumed,Seq,LitBuf,LitSize);
     End;
  Else
   ZstdBufFree(LitBuf);
   WriteLn('Bloc Zstandard reserve invalide.');
   Halt(1);
  End;
 Until LastBlock;
 If ChecksumFlag Then ZstdSkip(4);
 ZstdBufFree(LitBuf);
End;

Procedure InflateZstd;
Var
 Magic:LongInt;
 Size:LongInt;
Begin
 InitWindow(False);
 Repeat
  Magic:=ZstdReadDWordLE;
  If(Magic and $FFFFFFF0)=LongInt($184D2A50)Then Begin
   Size:=ZstdReadDWordLE;
   ZstdSkip(Size);
  End
   Else If Magic=LongInt($FD2FB528)Then Begin
   InflateZstdFrame;
  End
   Else
  Begin
   WriteLn('Signature Zstandard invalide.');
   Halt(1);
  End;
 Until(OutSize>=UncompSize)or(CompLeft<=0);
End;

Procedure BZAllocTT(Limit:LongInt);
Var
 I,Need:Integer;
Begin
 BZBlockLimit:=Limit;
 Need:=(Limit+BZChunkSize-1)div BZChunkSize;
 If Need>BZMaxChunks Then Begin
  WriteLn('Bloc BZIP2 trop grand.');
  Halt(1);
 End;
 For I:=0 to BZMaxChunks-1 do BZTT[I]:=NIL;
 For I:=0 to BZMaxChunks-1 do BZByte[I]:=NIL;
 For I:=0 to Need-1 do Begin
  GetMem(BZTT[I],SizeOf(TBZTTChunk));
  GetMem(BZByte[I],SizeOf(TBZByteChunk));
  If(BZTT[I]=NIL)or(BZByte[I]=NIL)Then Begin
   WriteLn('Memoire insuffisante pour BZIP2.');
   Halt(1);
  End;
 End;
End;

Procedure BZFreeTT;
Var
 I:Integer;
Begin
 For I:=0 to BZMaxChunks-1 do If BZTT[I]<>NIL Then Begin
  FreeMem(BZTT[I],SizeOf(TBZTTChunk));
  BZTT[I]:=NIL;
 End;
 For I:=0 to BZMaxChunks-1 do If BZByte[I]<>NIL Then Begin
  FreeMem(BZByte[I],SizeOf(TBZByteChunk));
  BZByte[I]:=NIL;
 End;
End;

Procedure BZSetTT(Pos,Value:LongInt);
Var
 C,O:Integer;
Begin
 If(Pos<0)or(Pos>=BZBlockLimit)Then Begin
  BZFreeTT;
  WriteLn('Index BZIP2 invalide.');
  Halt(1);
 End;
 C:=Pos div BZChunkSize;
 O:=Pos mod BZChunkSize;
 BZTT[C]^[O]:=Value;
End;

Function BZGetTT(Pos:LongInt):LongInt;
Var
 C,O:Integer;
Begin
 If(Pos<0)or(Pos>=BZBlockLimit)Then Begin
  BZFreeTT;
  WriteLn('Index BZIP2 invalide.');
  Halt(1);
 End;
 C:=Pos div BZChunkSize;
 O:=Pos mod BZChunkSize;
 BZGetTT:=BZTT[C]^[O];
End;

Procedure BZSetByte(Pos:LongInt;B:Byte);
Var
 C,O:Integer;
Begin
 If(Pos<0)or(Pos>=BZBlockLimit)Then Begin
  BZFreeTT;
  WriteLn('Index BZIP2 invalide.');
  Halt(1);
 End;
 C:=Pos div BZChunkSize;
 O:=Pos mod BZChunkSize;
 BZByte[C]^[O]:=B;
End;

Function BZGetByte(Pos:LongInt):Byte;
Var
 C,O:Integer;
Begin
 If(Pos<0)or(Pos>=BZBlockLimit)Then Begin
  BZFreeTT;
  WriteLn('Index BZIP2 invalide.');
  Halt(1);
 End;
 C:=Pos div BZChunkSize;
 O:=Pos mod BZChunkSize;
 BZGetByte:=BZByte[C]^[O];
End;

Function BZReadBit:Integer;
Begin
 If BZBitCount=0 Then Begin
  BZBitBuf:=ReadCompByte;
  BZBitCount:=8;
 End;
 Dec(BZBitCount);
 BZReadBit:=(BZBitBuf shr BZBitCount)and 1;
End;

Function BZReadBits(N:Integer):LongInt;
Var
 I:Integer;
 V:LongInt;
Begin
 V:=0;
 For I:=1 to N do V:=(V shl 1)or BZReadBit;
 BZReadBits:=V;
End;

Function BZReadByte:Byte;
Begin
 BZReadByte:=Byte(BZReadBits(8));
End;

Function BZReadMagic:String;
Var
 I:Integer;
 S:String;
Begin
 S:='';
 For I:=1 to 6 do S:=S+Chr(BZReadByte);
 BZReadMagic:=S;
End;

Procedure BZBuildHuffman(Var H:BZHuffman;Var Lengths;N:Integer);
Type
 TLengths=Array[0..BZMaxAlphaSize-1]of Byte;
Var
 L:^TLengths;
 Count:Array[0..BZMaxAlphaSize]of Integer;
 NextCode:Array[0..BZMaxAlphaSize]of LongInt;
 I,Bits:Integer;
 Code:LongInt;
Begin
 L:=@Lengths;
 H.MinLen:=99;
 H.MaxLen:=0;
 For I:=0 to BZMaxAlphaSize-1 do Begin
  H.Len[I]:=0;
  H.Code[I]:=0;
 End;
 For I:=0 to BZMaxAlphaSize do Count[I]:=0;
 For I:=0 to N-1 do Begin
  H.Len[I]:=L^[I];
  If H.Len[I]>0 Then Begin
   Inc(Count[H.Len[I]]);
   If H.Len[I]<H.MinLen Then H.MinLen:=H.Len[I];
   If H.Len[I]>H.MaxLen Then H.MaxLen:=H.Len[I];
  End;
 End;
 Code:=0;
 Count[0]:=0;
 For Bits:=1 to BZMaxAlphaSize do Begin
  Code:=(Code+Count[Bits-1])shl 1;
  NextCode[Bits]:=Code;
 End;
 For I:=0 to N-1 do Begin
  Bits:=H.Len[I];
  If Bits<>0 Then Begin
   H.Code[I]:=NextCode[Bits];
   Inc(NextCode[Bits]);
  End;
 End;
End;

Function BZDecodeSymbol(Var H:BZHuffman;AlphaSize:Integer):Integer;
Var
 Len,Sym:Integer;
 Code:LongInt;
Begin
 Code:=0;
 For Len:=1 to H.MaxLen do Begin
  Code:=(Code shl 1)or BZReadBit;
  If Len>=H.MinLen Then Begin
   For Sym:=0 to AlphaSize-1 do
    If(H.Len[Sym]=Len)and(H.Code[Sym]=Code)Then Begin
     BZDecodeSymbol:=Sym;
     Exit;
    End;
  End;
 End;
 BZFreeTT;
 WriteLn('Code Huffman BZIP2 invalide.');
 Halt(1);
 BZDecodeSymbol:=0;
End;

Procedure BZMoveToFront(Var A;Pos:Integer);
Type
 TByteList=Array[0..255]of Byte;
Var
 L:^TByteList;
 V:Byte;
 I:Integer;
Begin
 L:=@A;
 V:=L^[Pos];
 For I:=Pos downto 1 do L^[I]:=L^[I-1];
 L^[0]:=V;
End;

Procedure BZPutBlockByte(B:Byte;Var NBlock:LongInt;Var Count);
Type
 TCounts=Array[0..255]of LongInt;
Var
 C:^TCounts;
Begin
 C:=@Count;
 If NBlock>=BZBlockLimit Then Begin
  BZFreeTT;
  WriteLn('Bloc BZIP2 trop long.');
  Halt(1);
 End;
 BZSetByte(NBlock,B);
 Inc(C^[B]);
 Inc(NBlock);
End;

Procedure BZDecodeBlock(BlockSize:Integer);
Type
 TBool16=Array[0..15]of Boolean;
 TInUse=Array[0..255]of Boolean;
 TByteList=Array[0..255]of Byte;
 TSelectors=Array[0..BZMaxSelectors-1]of Byte;
 TGroups=Array[0..BZMaxGroups-1]of BZHuffman;
 TLengths=Array[0..BZMaxAlphaSize-1]of Byte;
 TCounts=Array[0..255]of LongInt;
Var
 Magic:String;
 InUse16:TBool16;
 InUse:TInUse;
 SeqToUnseq,MTF:TByteList;
 Selectors:TSelectors;
 Groups:TGroups;
 Lengths:TLengths;
 Counts,Cftab:TCounts;
 BlockCRC,NBlock,OrigPtr,TPos,V:LongInt;
 Randomized:Boolean;
 I,J,K,AlphaSize,NInUse,NGroups,NSelectors,Sel,Sym:Integer;
 CurrLen,RepCount,RunPower,GroupNo,GroupPos,EOB:Integer;
 Ch,LastCh:Integer;
 SameCount:Integer;
 NeedRepeat:Boolean;

 Procedure EmitByte(B:Byte);
 Var
  R:Integer;
Begin
  If NeedRepeat Then Begin
   For R:=1 to B do PutOutByte(Byte(LastCh));
   NeedRepeat:=False;
   SameCount:=0;
   LastCh:=-1;
   Exit;
  End;
  PutOutByte(B);
  If LastCh=B Then Inc(SameCount)
  Else Begin
   LastCh:=B;
   SameCount:=1;
  End;
  If SameCount=4 Then NeedRepeat:=True;
 End;

Begin
 Magic:=BZReadMagic;
 If Magic=#$17#$72#$45#$38#$50#$90 Then Begin
  BZReadBits(32);
  Exit;
 End;
 If Magic<>#$31#$41#$59#$26#$53#$59 Then Begin
  BZFreeTT;
  WriteLn('Bloc BZIP2 invalide.');
  Halt(1);
 End;
 BlockCRC:=BZReadBits(32);
 If BlockCRC=0 Then Begin End;
 Randomized:=BZReadBit<>0;
 If Randomized Then Begin
  BZFreeTT;
  WriteLn('BZIP2 randomise non supporte.');
  Halt(1);
 End;
 OrigPtr:=BZReadBits(24);
 For I:=0 to 15 do InUse16[I]:=BZReadBit<>0;
 For I:=0 to 255 do InUse[I]:=False;
 For I:=0 to 15 do If InUse16[I] Then
  For J:=0 to 15 do InUse[I*16+J]:=BZReadBit<>0;
 NInUse:=0;
 For I:=0 to 255 do If InUse[I] Then Begin
  SeqToUnseq[NInUse]:=I;
  Inc(NInUse);
 End;
 AlphaSize:=NInUse+2;
 EOB:=NInUse+1;
 NGroups:=BZReadBits(3);
 NSelectors:=BZReadBits(15);
 If(NGroups<2)or(NGroups>BZMaxGroups)or
   (NSelectors<1)or(NSelectors>BZMaxSelectors)Then Begin
  BZFreeTT;
  WriteLn('Selecteurs BZIP2 invalides.');
  Halt(1);
 End;
 For I:=0 to NGroups-1 do MTF[I]:=I;
 For I:=0 to NSelectors-1 do Begin
  J:=0;
  While BZReadBit<>0 do Inc(J);
  If J>=NGroups Then Begin
   BZFreeTT;
   WriteLn('Selecteur BZIP2 invalide.');
   Halt(1);
  End;
  Selectors[I]:=MTF[J];
  BZMoveToFront(MTF,J);
 End;
 For I:=0 to NGroups-1 do Begin
  CurrLen:=BZReadBits(5);
  For J:=0 to AlphaSize-1 do Begin
   While BZReadBit<>0 do Begin
    If BZReadBit=0 Then Inc(CurrLen)
                   Else Dec(CurrLen);
    If(CurrLen<1)or(CurrLen>23)Then Begin
     BZFreeTT;
     WriteLn('Longueur Huffman BZIP2 invalide.');
     Halt(1);
    End;
   End;
   Lengths[J]:=CurrLen;
  End;
  BZBuildHuffman(Groups[I],Lengths,AlphaSize);
 End;
 For I:=0 to 255 do Begin
  MTF[I]:=I;
  Counts[I]:=0;
  Cftab[I]:=0;
 End;
 NBlock:=0;
 GroupNo:=-1;
 GroupPos:=0;
 Sel:=0;
 RepCount:=0;
 RunPower:=1;
 Repeat
  If GroupPos=0 Then Begin
   Inc(GroupNo);
   If GroupNo>=NSelectors Then Begin
    BZFreeTT;
    WriteLn('Flux BZIP2 trop long.');
    Halt(1);
   End;
   Sel:=Selectors[GroupNo];
   GroupPos:=BZGroupSize;
  End;
  Dec(GroupPos);
  Sym:=BZDecodeSymbol(Groups[Sel],AlphaSize);
  If(Sym=0)or(Sym=1)Then Begin
   RepCount:=0;
   RunPower:=1;
   Repeat
    If Sym=0 Then Inc(RepCount,RunPower)
             Else Inc(RepCount,RunPower*2);
    RunPower:=RunPower*2;
    If GroupPos=0 Then Begin
     Inc(GroupNo);
     If GroupNo>=NSelectors Then Begin
      BZFreeTT;
      WriteLn('Flux BZIP2 trop long.');
      Halt(1);
     End;
     Sel:=Selectors[GroupNo];
     GroupPos:=BZGroupSize;
    End;
    Dec(GroupPos);
    Sym:=BZDecodeSymbol(Groups[Sel],AlphaSize);
   Until(Sym<>0)and(Sym<>1);
   Ch:=SeqToUnseq[MTF[0]];
   For K:=1 to RepCount do BZPutBlockByte(Ch,NBlock,Counts);
  End;
  If(Sym<>EOB)Then Begin
   J:=Sym-1;
   If(J<0)or(J>=NInUse)Then Begin
    BZFreeTT;
    WriteLn('Symbole BZIP2 invalide.');
    Halt(1);
   End;
   Ch:=SeqToUnseq[MTF[J]];
   BZPutBlockByte(Ch,NBlock,Counts);
   BZMoveToFront(MTF,J);
  End;
 Until Sym=EOB;
 If(OrigPtr<0)or(OrigPtr>=NBlock)Then Begin
  BZFreeTT;
  WriteLn('OrigPtr BZIP2 invalide.');
  Halt(1);
 End;
 Cftab[0]:=0;
 For I:=1 to 255 do Cftab[I]:=Cftab[I-1]+Counts[I-1];
 For I:=0 to NBlock-1 do Begin
  Ch:=BZGetByte(I);
  V:=Cftab[Ch];
  BZSetTT(V,I);
  Inc(Cftab[Ch]);
 End;
 TPos:=OrigPtr;
 LastCh:=-1;
 SameCount:=0;
 NeedRepeat:=False;
 For I:=1 to NBlock do Begin
  TPos:=BZGetTT(TPos);
  Ch:=BZGetByte(TPos);
  EmitByte(Byte(Ch));
 End;
 If NeedRepeat Then Begin
  BZFreeTT;
  WriteLn('Fin de bloc BZIP2 invalide.');
  Halt(1);
 End;
 BZDecodeBlock(BlockSize);
End;

Procedure InflateBZip2;
Var
 B1,B2,B3,Level:Byte;
Begin
 InitWindow(False);
 BZBitBuf:=0;
 BZBitCount:=0;
 B1:=BZReadByte;
 B2:=BZReadByte;
 B3:=BZReadByte;
 If(B1<>Ord('B'))or(B2<>Ord('Z'))or(B3<>Ord('h'))Then Begin
  WriteLn('En-tete BZIP2 invalide.');
  Halt(1);
 End;
 Level:=BZReadByte;
 If(Level<Ord('1'))or(Level>Ord('9'))Then Begin
  WriteLn('Taille de bloc BZIP2 invalide.');
  Halt(1);
 End;
 BZAllocTT((Level-Ord('0'))*100000);
 BZDecodeBlock(Level-Ord('0'));
 BZFreeTT;
End;

Procedure ReadImplodeTree(Var H:Huffman;Symbols:Integer);
Var
 Lengths:Array[0..MaxSymbols-1]of Byte;
 I,J,N,B,L,R,Posi:Integer;
Begin
 For I:=0 to MaxSymbols-1 do Lengths[I]:=0;
 N:=ReadCompByte+1;
 Posi:=0;
 For I:=1 to N do Begin
  B:=ReadCompByte;
  L:=(B and 15)+1;
  R:=((B shr 4)and 15)+1;
  For J:=1 to R do Begin
   If Posi>=Symbols Then Begin
    WriteLn('Arbre Implode invalide.');
    Halt(1);
   End;
   Lengths[Posi]:=L;
   Inc(Posi);
  End;
 End;
 If Posi<>Symbols Then Begin
  WriteLn('Arbre Implode incomplet.');
  Halt(1);
 End;
 BuildHuffmanInvert(H,Lengths,Symbols);
End;

Procedure Explode(Flags:Integer);
Var
 Lit,LenTree,DistTree:Huffman;
 HasLit,LargeWin:Boolean;
 DistBits,MinLen,Token,Sym,Len,Dist,Low,I,WinRead:Integer;
 B:Byte;
Begin
 BitBuf:=0;
 BitCount:=0;
 InitWindow(False);
 LargeWin:=(Flags and 2)<>0;
 HasLit:=(Flags and 4)<>0;
 DistBits:=6;
 If LargeWin Then DistBits:=7;
 MinLen:=2;
 If HasLit Then MinLen:=3;
 If HasLit Then ReadImplodeTree(Lit,256);
 ReadImplodeTree(LenTree,64);
 ReadImplodeTree(DistTree,64);
 While OutSize<UncompSize do Begin
  Token:=ReadBit;
  If Token<>0 Then Begin
   If HasLit Then B:=Byte(DecodeSymbol(Lit))
             Else B:=Byte(ReadBits(8));
   PutOutByte(B);
  End
   Else
  Begin
   Low:=ReadBits(DistBits);
   Sym:=DecodeSymbol(DistTree);
   Dist:=(Sym shl DistBits)+Low+1;
   Sym:=DecodeSymbol(LenTree);
   Len:=Sym+MinLen;
   If Sym=63 Then Inc(Len,ReadBits(8));
   If(OutSize+Len>UncompSize)or(Dist>OutSize)Then Begin
    WriteLn('Reference Implode invalide.');
    Halt(1);
   End;
   For I:=1 to Len do Begin
    WinRead:=(WinPos-Dist)and $7FFF;
    B:=GetWindowByte(WinRead);
    PutOutByte(B);
   End;
  End;
 End;
 AlignByte;
End;

Procedure ShrinkInit;
Var
 I:Integer;
Begin
 If ShrinkPrefix=NIL Then GetMem(ShrinkPrefix,SizeOf(TShrinkIntArray));
 If ShrinkSuffix=NIL Then GetMem(ShrinkSuffix,SizeOf(TShrinkByteArray));
 If ShrinkActive=NIL Then GetMem(ShrinkActive,SizeOf(TShrinkBoolArray));
 If ShrinkStack=NIL Then GetMem(ShrinkStack,SizeOf(TShrinkByteArray));
 If(ShrinkPrefix=NIL)or(ShrinkSuffix=NIL)or
   (ShrinkActive=NIL)or(ShrinkStack=NIL)Then Begin
  WriteLn('Memoire insuffisante pour Shrink.');
  Halt(1);
 End;
 For I:=0 to ShrinkMaxCode do Begin
  ShrinkPrefix^[I]:=-1;
  ShrinkSuffix^[I]:=0;
  ShrinkActive^[I]:=False;
 End;
 For I:=0 to 255 do Begin
  ShrinkSuffix^[I]:=I;
  ShrinkActive^[I]:=True;
 End;
 ShrinkActive^[256]:=False;
End;

Procedure ShrinkDone;
Begin
 If ShrinkPrefix<>NIL Then Begin
  FreeMem(ShrinkPrefix,SizeOf(TShrinkIntArray));
  ShrinkPrefix:=NIL;
 End;
 If ShrinkSuffix<>NIL Then Begin
  FreeMem(ShrinkSuffix,SizeOf(TShrinkByteArray));
  ShrinkSuffix:=NIL;
 End;
 If ShrinkActive<>NIL Then Begin
  FreeMem(ShrinkActive,SizeOf(TShrinkBoolArray));
  ShrinkActive:=NIL;
 End;
 If ShrinkStack<>NIL Then Begin
  FreeMem(ShrinkStack,SizeOf(TShrinkByteArray));
  ShrinkStack:=NIL;
 End;
End;

Function ShrinkFindFree:Integer;
Var
 I:Integer;
Begin
 For I:=257 to ShrinkMaxCode do Begin
  If Not ShrinkActive^[I]Then Begin
   ShrinkFindFree:=I;
   Exit;
  End;
 End;
 ShrinkFindFree:=-1;
End;

Procedure ShrinkAdd(Prefix:Integer;Suffix:Byte);
Var
 N:Integer;
Begin
 N:=ShrinkFindFree;
 If N<0Then Exit;
 ShrinkPrefix^[N]:=Prefix;
 ShrinkSuffix^[N]:=Suffix;
 ShrinkActive^[N]:=True;
End;

Procedure ShrinkPartialClear;
Var
 I:Integer;
 Used:PShrinkBoolArray;
Begin
 GetMem(Used,SizeOf(TShrinkBoolArray));
 If Used=NIL Then Begin
  WriteLn('Memoire insuffisante pour Shrink.');
  Halt(1);
 End;
 For I:=0 to ShrinkMaxCode do Used^[I]:=False;
 For I:=257 to ShrinkMaxCode do Begin
  If ShrinkActive^[I]and(ShrinkPrefix^[I]>=257)Then
   Used^[ShrinkPrefix^[I]]:=True;
 End;
 For I:=257 to ShrinkMaxCode do Begin
  If ShrinkActive^[I]and(Not Used^[I])Then Begin
   ShrinkActive^[I]:=False;
   ShrinkPrefix^[I]:=-1;
   ShrinkSuffix^[I]:=0;
  End;
 End;
 FreeMem(Used,SizeOf(TShrinkBoolArray));
End;

Function ShrinkDecodeToStack(Code:Integer;Var FirstChar:Byte):Integer;
Var
 Top,Guard:Integer;
Begin
 Top:=0;
 Guard:=0;
 While Code>=0 do Begin
  If(Code>ShrinkMaxCode)or(Not ShrinkActive^[Code])Then Begin
   WriteLn('Code Shrink invalide.');
   Halt(1);
  End;
  ShrinkStack^[Top]:=ShrinkSuffix^[Code];
  Inc(Top);
  If Code<256Then Break;
  Code:=ShrinkPrefix^[Code];
  Inc(Guard);
  If Guard>ShrinkMaxCode Then Begin
   WriteLn('Boucle Shrink invalide.');
   Halt(1);
  End;
 End;
 FirstChar:=ShrinkStack^[Top-1];
 ShrinkDecodeToStack:=Top;
End;

Procedure ShrinkOutputStack(Top:Integer);
Var
 I:Integer;
Begin
 For I:=Top-1 downto 0 do PutOutByte(ShrinkStack^[I]);
End;

Function ShrinkReadCode(CodeSize:Integer):Integer;
Begin
 ShrinkReadCode:=ReadBits(CodeSize);
End;

Procedure UnShrink;
Var
 CodeSize,Code,OldCode,SubCode,Top:Integer;
 FirstChar,OldFirstChar:Byte;
Begin
 BitBuf:=0;
 BitCount:=0;
 InitWindow(False);
 ShrinkInit;
 CodeSize:=9;
 OldCode:=-1;
 OldFirstChar:=0;
 While OutSize<UncompSize do Begin
  Code:=ShrinkReadCode(CodeSize);
  If Code=256Then Begin
   SubCode:=ShrinkReadCode(CodeSize);
   If SubCode=1Then Begin
    If CodeSize<13Then Inc(CodeSize);
   End
    Else If SubCode=2Then ShrinkPartialClear
    Else Begin
     ShrinkDone;
     WriteLn('Commande Shrink inconnue.');
     Halt(1);
    End;
  End
   Else
  Begin
   If OldCode<0Then Begin
    Top:=ShrinkDecodeToStack(Code,FirstChar);
    ShrinkOutputStack(Top);
    OldCode:=Code;
    OldFirstChar:=FirstChar;
   End
    Else
   Begin
    If(Code<=ShrinkMaxCode)and(ShrinkActive^[Code])Then Begin
     Top:=ShrinkDecodeToStack(Code,FirstChar);
     ShrinkOutputStack(Top);
    End
     Else
    Begin
     Top:=ShrinkDecodeToStack(OldCode,FirstChar);
     ShrinkOutputStack(Top);
     PutOutByte(OldFirstChar);
     FirstChar:=OldFirstChar;
    End;
    ShrinkAdd(OldCode,FirstChar);
    OldCode:=Code;
    OldFirstChar:=FirstChar;
   End;
  End;
 End;
 ShrinkDone;
 AlignByte;
End;

Function FollowerBits(N:Integer):Integer;
Begin
 If N>16Then FollowerBits:=5
  Else If N>8Then FollowerBits:=4
  Else If N>4Then FollowerBits:=3
  Else If N>2Then FollowerBits:=2
  Else If N>0Then FollowerBits:=1
  Else FollowerBits:=0;
End;

Procedure ReduceInit;
Var
 I,J,N:Integer;
Begin
 If ReduceSize=NIL Then GetMem(ReduceSize,SizeOf(TFollowerSizeArray));
 If ReduceBits=NIL Then GetMem(ReduceBits,SizeOf(TFollowerSizeArray));
 If ReduceFollowers=NIL Then GetMem(ReduceFollowers,SizeOf(TFollowerArray));
 If(ReduceSize=NIL)or(ReduceBits=NIL)or(ReduceFollowers=NIL)Then Begin
  WriteLn('Memoire insuffisante pour Reduce.');
  Halt(1);
 End;
 For I:=0 to 255 do Begin
  ReduceSize^[I]:=0;
  ReduceBits^[I]:=0;
  For J:=0 to 31 do ReduceFollowers^[I,J]:=0;
 End;
 For I:=255 downto 0 do Begin
  N:=ReadBits(6);
  If N>32Then Begin
   WriteLn('Follower set Reduce invalide.');
   Halt(1);
  End;
  ReduceSize^[I]:=N;
  ReduceBits^[I]:=FollowerBits(N);
  For J:=0 to N-1 do ReduceFollowers^[I,J]:=ReadBits(8);
 End;
End;

Procedure ReduceDone;
Begin
 If ReduceSize<>NIL Then Begin
  FreeMem(ReduceSize,SizeOf(TFollowerSizeArray));
  ReduceSize:=NIL;
 End;
 If ReduceBits<>NIL Then Begin
  FreeMem(ReduceBits,SizeOf(TFollowerSizeArray));
  ReduceBits:=NIL;
 End;
 If ReduceFollowers<>NIL Then Begin
  FreeMem(ReduceFollowers,SizeOf(TFollowerArray));
  ReduceFollowers:=NIL;
 End;
End;

Function ReduceReadByte(Prev:Byte):Byte;
Var
 Idx:Integer;
Begin
 If ReduceSize^[Prev]=0 Then Begin
  ReduceReadByte:=ReadBits(8);
 End
  Else If ReadBit=1 Then Begin
  ReduceReadByte:=ReadBits(8);
 End
  Else
 Begin
  Idx:=ReadBits(ReduceBits^[Prev]);
  If Idx>=ReduceSize^[Prev]Then Begin
   ReduceDone;
   WriteLn('Index follower Reduce invalide.');
   Halt(1);
  End;
  ReduceReadByte:=ReduceFollowers^[Prev,Idx];
 End;
End;

Procedure UnReduce(Factor:Integer);
Var
 Prev,V,W,B:Byte;
 LenBits,LenMask,Len,Dist,I,WinRead:Integer;
Begin
 BitBuf:=0;
 BitCount:=0;
 InitWindow(False);
 ReduceInit;
 Prev:=0;
 LenBits:=8-Factor;
 LenMask:=(1 shl LenBits)-1;
 While OutSize<UncompSize do Begin
  B:=ReduceReadByte(Prev);
  Prev:=B;
 If B<>DLEByte Then Begin
   PutOutByte(B);
  End
   Else
  Begin
   V:=ReduceReadByte(Prev);
   Prev:=V;
   If V=0 Then PutOutByte(DLEByte)
    Else
   Begin
    Len:=V and LenMask;
    If Len=LenMask Then Begin
     B:=ReduceReadByte(Prev);
     Prev:=B;
     Inc(Len,B);
    End;
    Inc(Len,3);
    W:=ReduceReadByte(Prev);
    Prev:=W;
    Dist:=((V shr LenBits)*256)+W+1;
    If OutSize+Len>UncompSize Then Begin
     ReduceDone;
     WriteLn('Reference Reduce trop longue.');
     Halt(1);
    End;
    For I:=1 to Len do Begin
     If Dist>OutSize Then PutOutByte(0)
      Else
     Begin
      WinRead:=(WinPos-Dist)and $7FFF;
      PutOutByte(GetWindowByte(WinRead));
     End;
    End;
   End;
  End;
 End;
 ReduceDone;
 AlignByte;
End;

Function CleanName(S:String):String;
Var
 I:Integer;
 R:String;
Begin
 R:='';
 For I:=1 to Length(S)do Begin
  If S[I]='/'Then R:=R+'\'
             Else R:=R+S[I];
 End;
 If Not KeepFullPath Then Begin
  While(Pos('..',R)>0)do Delete(R,Pos('..',R),2);
  If(Pos(':',R)>0)Then Delete(R,1,Pos(':',R));
  While(Length(R)>0)and((R[1]='\')or(R[1]='/'))do Delete(R,1,1);
 End;
 If JunkPaths Then R:=BaseName(R);
 If LowerNames Then R:=LowStr(R);
 If DestDir<>''Then R:=JoinPath(DestDir,R);
 CleanName:=R;
End;

Function MatchPattern(Pat,Name:String):Boolean;
Var
 P,N,Star,Mark:Integer;
Begin
 If CaseInsensitive Then Begin
  Pat:=UpStr(Pat);
  Name:=UpStr(Name);
 End;
 P:=1; N:=1; Star:=0; Mark:=0;
 While N<=Length(Name)do Begin
  If(P<=Length(Pat))and((Pat[P]='?')or(Pat[P]=Name[N]))Then Begin
   Inc(P); Inc(N);
  End
   Else If(P<=Length(Pat))and(Pat[P]='*')Then Begin
   Star:=P; Inc(P); Mark:=N;
  End
   Else If Star<>0 Then Begin
   P:=Star+1; Inc(Mark); N:=Mark;
  End
   Else
  Begin
   MatchPattern:=False;
   Exit;
  End;
 End;
 While(P<=Length(Pat))and(Pat[P]='*')do Inc(P);
 MatchPattern:=P>Length(Pat);
End;

Function IsExcluded(Name:String):Boolean;
Var
 I:Integer;
 ShortName:String;
Begin
 ShortName:=BaseName(Name);
 For I:=1 to ExcludeCount do Begin
  If MatchPattern(ExcludeList[I],Name)or MatchPattern(ExcludeList[I],ShortName)Then Begin
   IsExcluded:=True;
   Exit;
  End;
 End;
 IsExcluded:=False;
End;

Function MethodName(Method:Integer):String;
Var
 S:String;
Begin
 Case Method of
  0:MethodName:='store';
  1:MethodName:='shrink';
  2,3,4,5:Begin
     Str(Method,S);
     MethodName:='reduce-'+S;
    End;
  6:MethodName:='implode';
  7:MethodName:='tokenize';
  8:MethodName:='deflate';
  9:MethodName:='deflate64';
  10:MethodName:='dcl-implode';
  12:MethodName:='bzip2';
  14:MethodName:='lzma';
  18:MethodName:='ibm-terse';
  19:MethodName:='ibm-lz77';
  93:MethodName:='zstandard';
 Else
  Str(Method,S);
  MethodName:=S;
 End;
End;

Procedure MakePath(S:String);
Var
 I:Integer;
 P:String;
Begin
 P:='';
 For I:=1 to Length(S)do Begin
  If S[I]='\'Then Begin
   If P<>''Then Begin
    {$I-}MkDir(P);{$I+}
    If IoResult<>0 Then ; { dir already exists or unwritable - silent }
   End;
  End;
  P:=P+S[I];
 End;
End;

Procedure SkipBytes(N:LongInt);
Begin
 While N>0 do Begin
  ReadZipByte;
  Dec(N);
 End;
End;

Procedure PrepareZipCrypto(Flags:Integer;CRC:LongInt;Name:String);
Var
 I:Integer;
 B,CheckByte:Byte;
Begin
 ZipCryptActive:=False;
 If(Flags and 1)=0 Then Exit;
 If Password=''Then Begin
  WriteLn('Mot de passe requis pour ',Name);
  Halt(1);
 End;
 If(Flags and $40)<>0 Then Begin
  WriteLn('Chiffrement fort ZIP non supporte: ',Name);
  Halt(1);
 End;
 If CompLeft<12 Then Begin
  WriteLn('En-tete de chiffrement ZIP invalide: ',Name);
  Halt(1);
 End;
 ZipCryptInit(Password);
 ZipCryptActive:=True;
 CheckByte:=0;
 For I:=1 to 12 do Begin
  B:=ReadCompByte;
  If I=12 Then CheckByte:=B;
 End;
 If CheckByte<>Byte(UShiftRight(CRC,24)and $FF)Then Begin
  WriteLn('Mot de passe incorrect ou en-tete ZIP chiffre invalide: ',Name);
  Halt(1);
 End;
End;

Procedure ExtractArchive;
Var
 Sig:LongInt;
 Flags,Method,NameLen,ExtraLen,ZipTime,ZipDate:Integer;
 CRC,CompSize,ZipStamp,DiskStamp:LongInt;
 Name,OutName:String;
 I:Integer;
 B:Byte;
 IsDir:Boolean;
 DoSkip,Existing:Boolean;
Begin
 Repeat
  If FilePos(ZipFile)>=FileSize(ZipFile)Then Break;
  Sig:=ReadDWordLE;
  If Sig=$02014B50 Then Break;
  If Sig<>$04034B50 Then Begin
   WriteLn('Signature ZIP locale invalide.');
   Halt(1);
  End;
  ReadWordLE;
  Flags:=ReadWordLE;
  Method:=ReadWordLE;
  ZipTime:=ReadWordLE;
  ZipDate:=ReadWordLE;
  ZipStamp:=ZipDateTimeStamp(ZipTime,ZipDate);
  CRC:=ReadDWordLE;
  CompSize:=ReadDWordLE;
  UncompSize:=ReadDWordLE;
  NameLen:=ReadWordLE;
  ExtraLen:=ReadWordLE;
  Name:='';
  For I:=1 to NameLen do Name:=Name+Chr(ReadZipByte);
  SkipBytes(ExtraLen);
  OutName:=CleanName(Name);
  IsDir:=(OutName='')or(OutName[Length(OutName)]='\');
  DoSkip:=IsExcluded(Name);
  If(Flags and 8)<>0 Then Begin
   WriteLn('Archive avec descripteur de donnees non supportee: ',Name);
   Halt(1);
  End;
  If ListMode or VerboseMode Then Begin
   If Not DoSkip Then Begin
    If VerboseMode Then Begin
     MoreWriteLn(Name+'  size='+Long2Str(UncompSize)+
      '  comp='+Long2Str(CompSize)+'  method='+MethodName(Method)+
      '  crc='+Hex8(CRC));
    End
     Else
    MoreWriteLn(Name);
     End;
     SkipBytes(CompSize);
  End
   Else
  Begin
   If DoSkip Then Begin
    If Not QuietMode and Not VeryQuietMode Then MoreWriteLn('Exclusion '+Name);
    SkipBytes(CompSize);
   End
    Else If IsDir Then Begin
    If Not(TestMode or PipeMode or CatMode) Then Begin
     If OutName<>'' Then Begin
      {$I-}MkDir(OutName);{$I+}
      If IoResult<>0 Then ; { dir already exists - silent }
     End;
    End;
    SkipBytes(CompSize);
   End
    Else
   Begin
    Existing:=FileExists(OutName);
    If NeverOverwrite and Existing Then Begin
     If Not QuietMode and Not VeryQuietMode Then MoreWriteLn('Ignore '+OutName);
     SkipBytes(CompSize);
    End
     Else If FreshenMode and Not Existing Then Begin
     SkipBytes(CompSize);
    End
     Else If FreshenMode and Existing and GetFileDateTimeStamp(OutName,DiskStamp)
       and(DiskStamp>=ZipStamp)Then Begin
     If Not QuietMode and Not VeryQuietMode Then MoreWriteLn('A jour '+OutName);
     SkipBytes(CompSize);
    End
     Else If UpdateMode and Existing and GetFileDateTimeStamp(OutName,DiskStamp)
       and(DiskStamp>=ZipStamp)Then Begin
     If Not QuietMode and Not VeryQuietMode Then MoreWriteLn('A jour '+OutName);
     SkipBytes(CompSize);
    End
     Else
    Begin
     If OverwriteMode Then Begin End;
     If UpdateMode Then Begin End;
     If KeepUnicode Then Begin End;
     If RestoreAttr Then Begin End;
     If TestMode Then OutputMode:=2
      Else If PipeMode or CatMode Then OutputMode:=1
      Else OutputMode:=0;
     CompLeft:=CompSize;
     ZipCryptActive:=False;
     ExpectedCRC:=CRC;
     OutCRC:=LongInt($FFFFFFFF);
     OutSize:=0;
     PrevOutByte:=-1;
     PrepareZipCrypto(Flags,CRC,Name);
     If(OutputMode=0)Then Begin
      MakePath(OutName);
      If Not QuietMode and Not VeryQuietMode Then MoreWriteLn('Extraction '+OutName);
      Assign(OutFile,OutName);
      {$I-}Rewrite(OutFile,1);{$I+}
      If IoResult<>0 Then Begin
       WriteLn('Impossible de creer ',OutName);
       Halt(1);
      End;
     End
      Else If TestMode and Not QuietMode and Not VeryQuietMode Then
     MoreWriteLn('Test '+Name);
     Case Method of
      0:Begin
         InitWindow(False);
         While CompLeft>0 do Begin
          B:=ReadCompByte;
          PutOutByte(B);
         End;
        End;
      1:UnShrink;
      2:UnReduce(1);
      3:UnReduce(2);
      4:UnReduce(3);
      5:UnReduce(4);
      6:Explode(Flags);
      7:Begin
         If OutputMode=0 Then Close(OutFile);
         WriteLn('Methode ZIP 7 tokenizing reservee/non documentee: ',Name);
         Halt(1);
        End;
      8:InflateDeflate;
      9:InflateDeflate64;
      10:Begin
          InflateDCLImplode;
         End;
      12:Begin
          InflateBZip2;
         End;
      14:Begin
          InflateLZMA;
         End;
      18:Begin
          InflateTerse;
         End;
      19:Begin
          If OutputMode=0 Then Close(OutFile);
          WriteLn('Methode ZIP 19 IBM LZ77 z Architecture/PFS non portable: ',Name);
          WriteLn('Cette methode depend du format CMPSC/dictionnaire IBM z/Architecture.');
          Halt(1);
         End;
      93:Begin
          InflateZstd;
         End;
     Else
      If OutputMode=0 Then Close(OutFile);
      WriteLn('Methode ZIP non supportee (',Method,') pour ',Name);
      Halt(1);
     End;
     OutCRC:=OutCRC xor LongInt($FFFFFFFF);
     If CompLeft>0 Then SkipBytes(CompLeft);
     If(OutSize<>UncompSize)or Not SameDWord(OutCRC,ExpectedCRC)Then Begin
      If OutputMode=0 Then Close(OutFile);
      WriteLn('Erreur CRC/taille pour ',Name);
      If Not VeryQuietMode Then
       WriteLn('  taille=',OutSize,'/',UncompSize,
        ' crc=',Hex8(OutCRC),'/',Hex8(ExpectedCRC));
      Halt(1);
     End;
     If OutputMode=0 Then Begin
      Close(OutFile);
      SetFileDateTimeStamp(OutName,ZipStamp);
     End;
    End;
   End;
  End;
 Until False;
End;

Procedure ShowHelp;
Begin
 WriteLn('UNZIP : Cette commande permet d''extraire une archive ZIP.');
 WriteLn;
 WriteLn('Syntaxe : UNZIP [options] archive.ZIP');
 WriteLn;
 WriteLn('Options :');
 WriteLn(' -l        Liste les fichiers');
 WriteLn(' -v        Liste detaillee');
 WriteLn(' -t        Teste les fichiers');
 WriteLn(' -x motif  Exclut un fichier');
 WriteLn(' -d rep    Repertoire de destination');
 WriteLn(' -o        Ecrase les fichiers existants');
 WriteLn(' -n        N''ecrase jamais');
 WriteLn(' -j        Ignore les chemins');
 WriteLn(' -q -qq    Mode silencieux');
 WriteLn(' -a        Conversion texte des fins de ligne');
 WriteLn(' -C        Recherche insensible a la casse');
 WriteLn(' -L        Noms en minuscules');
 WriteLn(' -f        Actualise seulement les fichiers existants');
 WriteLn(' -u        Met a jour/extrait les nouveaux');
 WriteLn(' -p        Envoie les fichiers vers stdout');
 WriteLn(' -c        Affiche les fichiers a l''ecran');
 WriteLn(' -z        Affiche le commentaire ZIP');
 WriteLn(' -M        Affichage page par page');
 WriteLn(' -P mot    Mot de passe ZipCrypto classique');
 WriteLn(' -X -U -:  Options reconnues pour compatibilite');
 WriteLn;
 WriteLn('Supporte les methodes ZIP store (0), shrink (1), ',
        'reduce (2-5), implode (6), deflate (8), Deflate64 (9), ');
 WriteLn('DCL Implode (10), BZIP2 (12), LZMA (14), IBM TERSE (18), ',
        'Zstandard/ZSTD (93).');
 WriteLn('Methode 7 tokenizing reconnue, mais reservee/non documentee.');
 WriteLn('Methode 10 DCL Implode/old IBM TERSE supportee.');
 WriteLn('IBM TERSE (18) supporte les flux PACK/SPACK avec en-tete TERSE.');
 WriteLn('Methode 19 IBM LZ77 z Architecture/PFS reconnue, non portable.');
 WriteLn('Methode 93 Zstandard: blocs Raw/RLE et compresses Huffman/FSE/LZ77.');
 WriteLn('BZIP2 utilise la memoire de tas par blocs pour l''inversion BWT.');
 WriteLn('LZMA utilise un dictionnaire sur tas; lc+lp doit etre <= 4.');
 WriteLn('Note : -P supporte ZipCrypto classique, pas AES/WinZip ni chiffrement fort.');
 WriteLn('-X restaure peu d''attributs; -f/-u comparent les dates ZIP/DOS.');
End;

Procedure ShowZipComment;
Var
 Pos,StartPos,Size:LongInt;
 Sig:LongInt;
 CommentLen,I:Integer;
 C:Char;
Begin
 Size:=FileSize(ZipFile);
 StartPos:=Size-66000;
 If StartPos<0 Then StartPos:=0;
 Pos:=Size-22;
 While Pos>=StartPos do Begin
  Seek(ZipFile,Pos);
  Sig:=ReadDWordLE;
  If Sig=$06054B50 Then Begin
   Seek(ZipFile,Pos+20);
   CommentLen:=ReadWordLE;
   If CommentLen>0 Then Begin
    MoreWriteLn('Commentaire ZIP:');
    For I:=1 to CommentLen do Begin
     C:=Chr(ReadZipByte);
     Write(C);
    End;
    WriteLn;
   End
    Else
   MoreWriteLn('Aucun commentaire ZIP.');
   Seek(ZipFile,0);
   Exit;
  End;
  Dec(Pos);
 End;
 MoreWriteLn('Commentaire ZIP introuvable.');
 Seek(ZipFile,0);
End;

Procedure InitOptions;
Var
 I:Integer;
Begin
 DestDir:='';
 Password:='';
 WindowLo:=NIL;
 WindowHi:=NIL;
 WindowMask:=$7FFF;
 ZipCryptActive:=False;
 ShrinkPrefix:=NIL;
 ShrinkSuffix:=NIL;
 ShrinkActive:=NIL;
 ShrinkStack:=NIL;
 ReduceSize:=NIL;
 ReduceBits:=NIL;
 ReduceFollowers:=NIL;
 ExcludeCount:=0;
 For I:=1 to MaxExclude do ExcludeList[I]:='';
 ListMode:=False;
 VerboseMode:=False;
 TestMode:=False;
 OverwriteMode:=False;
 NeverOverwrite:=False;
 JunkPaths:=False;
 QuietMode:=False;
 VeryQuietMode:=False;
 AutoText:=False;
 CaseInsensitive:=False;
 LowerNames:=False;
 KeepUnicode:=False;
 FreshenMode:=False;
 UpdateMode:=False;
 PipeMode:=False;
 CatMode:=False;
 ShowCommentMode:=False;
 MoreMode:=False;
 RestoreAttr:=False;
 KeepFullPath:=False;
 MoreLines:=0;
End;

Procedure ParseOptions;
Var
 I,J:Integer;
 P:String;
Begin
 ArchiveName:='';
 I:=1;
 While I<=ParamCount do Begin
  P:=ParamStr(I);
  If(P='/?')or(P='--help')or(P='/h')or(P='/H')Then Begin
   ShowHelp;
   Halt;
  End;
  If(Length(P)>0)and(P[1]='-')Then Begin
   If P='-qq'Then VeryQuietMode:=True
    Else If P='-d'Then Begin
    Inc(I);
    If I<=ParamCount Then DestDir:=ParamStr(I);
   End
    Else If P='-P'Then Begin
    Inc(I);
    If I<=ParamCount Then Password:=ParamStr(I);
   End
    Else If P='-x'Then Begin
    Inc(I);
    If(I<=ParamCount)and(ExcludeCount<MaxExclude)Then Begin
     Inc(ExcludeCount);
     ExcludeList[ExcludeCount]:=ParamStr(I);
    End;
   End
    Else
   Begin
    For J:=2 to Length(P)do Begin
     Case P[J] of
      'l':ListMode:=True;
      'v':VerboseMode:=True;
      't':TestMode:=True;
      'o':OverwriteMode:=True;
      'n':NeverOverwrite:=True;
      'j':JunkPaths:=True;
      'q':QuietMode:=True;
      'a':AutoText:=True;
      'C':CaseInsensitive:=True;
      'L':LowerNames:=True;
      'U':KeepUnicode:=True;
      'f':FreshenMode:=True;
      'u':UpdateMode:=True;
      'p':PipeMode:=True;
      'c':CatMode:=True;
      'z':ShowCommentMode:=True;
      'M':MoreMode:=True;
      'X':RestoreAttr:=True;
      ':':KeepFullPath:=True;
     End;
    End;
   End;
  End
   Else If ArchiveName=''Then ArchiveName:=P
   Else If ExcludeCount<MaxExclude Then Begin
    Inc(ExcludeCount);
    ExcludeList[ExcludeCount]:=P;
   End;
  Inc(I);
 End;
 If VerboseMode Then ListMode:=False;
End;

Function CorailUnzipExtract(Const AZipPath, ADestDir: String): Boolean;
Begin
 CorailUnzipExtract := False;
 InitOptions;
 ArchiveName  := AZipPath;
 DestDir      := ADestDir;
 OverwriteMode:= True;
 QuietMode    := True;
 VeryQuietMode:= True;
 ListMode     := False;
 VerboseMode  := False;
 TestMode     := False;
 PipeMode     := False;
 CatMode      := False;
 ShowCommentMode := False;
 InitCRC32;
 Assign(ZipFile,ArchiveName);
 {$I-}Reset(ZipFile,1);{$I+}
 If IoResult<>0 Then Exit;
 ExtractArchive;
 {$I-}Close(ZipFile);{$I+}
 If IoResult<>0 Then ;
 CorailUnzipExtract := True;
END;

{$POP}

{ === End CORAIL UNZIP include === }


Const
 VFX_BUF_SIZE = 524288;

Var
 VFX_Buf    : Array[0..VFX_BUF_SIZE - 1] of Char;
 VFX_BufLen : LongInt;
 VFX_TempDir: String;
 VFX_DummyFile: File;

Function VFXReadFileToBuf(Const FN: String): Boolean;
Var F: File; N: LongInt;
Begin
 VFXReadFileToBuf := False;
 VFX_BufLen := 0;
 Assign(F, FN);
 {$I-} Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 BlockRead(F, VFX_Buf[0], VFX_BUF_SIZE, N);
 Close(F);
 VFX_BufLen := N;
 VFXReadFileToBuf := N > 0;
End;

Function VFXFindFrom(Const Needle: String; StartAt: LongInt): LongInt;
Var I, K, NL: LongInt; OK: Boolean;
Begin
 VFXFindFrom := -1;
 NL := Length(Needle);
 If (NL = 0) Or (NL > VFX_BufLen) Then Exit;
 If StartAt < 0 Then StartAt := 0;
 I := StartAt;
 While I <= VFX_BufLen - NL Do Begin
  If VFX_Buf[I] = Needle[1] Then Begin
   OK := True;
   K := 2;
   While (K <= NL) And OK Do Begin
    If VFX_Buf[I + K - 1] <> Needle[K] Then OK := False;
    Inc(K);
   End;
   If OK Then Begin VFXFindFrom := I; Exit; End;
  End;
  Inc(I);
 End;
End;

Function VFXSubstr(StartIdx, EndIdx: LongInt): String;
Var S: String; I: LongInt; N: Integer;
Begin
 S := ''; N := 0; I := StartIdx;
 If I < 0 Then I := 0;
 If EndIdx > VFX_BufLen Then EndIdx := VFX_BufLen;
 While (I < EndIdx) And (N < 255) Do Begin
  Inc(N); S := S + VFX_Buf[I]; Inc(I);
 End;
 VFXSubstr := S;
End;

Function VFXStrToReal(Const S: String): Real;
Var I: Integer; T: String; Code: Integer; R: Real;
Begin
 T := '';
 For I := 1 To Length(S) Do
  If ((S[I] >= '0') And (S[I] <= '9')) Or (S[I] = '.') Or
     (S[I] = '-') Or (S[I] = '+') Or (S[I] = 'e') Or (S[I] = 'E') Then
   T := T + S[I];
 If T = '' Then Begin VFXStrToReal := 0; Exit; End;
 Val(T, R, Code);
 If Code <> 0 Then R := 0;
 VFXStrToReal := R;
End;

Function VFXFindCellValue(Start, EndIdx: LongInt;
                          Const CellName: String): String;
Var P, Q, R: LongInt; Pattern: String; Found: Boolean;
Begin
 VFXFindCellValue := '';
 Found := False;
 Pattern := 'N=''' + CellName + '''';
 P := VFXFindFrom(Pattern, Start);
 If (P >= 0) And (P < EndIdx) Then Found := True
 Else Begin
  Pattern := 'N="' + CellName + '"';
  P := VFXFindFrom(Pattern, Start);
  If (P >= 0) And (P < EndIdx) Then Found := True;
 End;
 If Not Found Then Exit;
 Q := P + Length(Pattern);
 While Q < EndIdx Do Begin
  If (VFX_Buf[Q] = '>') Or (VFX_Buf[Q] = '/') Then Exit;
  If (VFX_Buf[Q] = 'V') And (Q + 1 < EndIdx) And (VFX_Buf[Q + 1] = '=') Then Begin
   Q := Q + 2;
   If Q >= EndIdx Then Exit;
   If (VFX_Buf[Q] = '''') Or (VFX_Buf[Q] = '"') Then Begin
    Inc(Q); R := Q;
    While (R < EndIdx) And (VFX_Buf[R] <> '''') And (VFX_Buf[R] <> '"') Do
     Inc(R);
    VFXFindCellValue := VFXSubstr(Q, R);
   End;
   Exit;
  End;
  Inc(Q);
 End;
End;

Function VFXFindShapeText(Start, EndIdx: LongInt): String;
Var P, Q, R: LongInt; S: String; InTag: Boolean; C: Char;
Begin
 VFXFindShapeText := '';
 P := VFXFindFrom('<Text>', Start);
 If (P < 0) Or (P >= EndIdx) Then Exit;
 P := P + 6;
 Q := VFXFindFrom('</Text>', P);
 If (Q < 0) Or (Q > EndIdx) Then Q := EndIdx;
 S := ''; R := P; InTag := False;
 While (R < Q) And (Length(S) < 80) Do Begin
  C := VFX_Buf[R];
  If C = '<' Then InTag := True
  Else If C = '>' Then InTag := False
  Else If Not InTag Then Begin
   If (C = #10) Or (C = #13) Or (C = #9) Then C := ' ';
   If (C >= ' ') And (Ord(C) < 127) Then Begin
    If (C = ' ') And (Length(S) > 0) And (S[Length(S)] = ' ') Then
     { skip }
    Else
     S := S + C;
   End;
  End;
  Inc(R);
 End;
 While (Length(S) > 0) And (S[1] = ' ') Do Delete(S, 1, 1);
 While (Length(S) > 0) And (S[Length(S)] = ' ') Do Delete(S, Length(S), 1);
 VFXFindShapeText := S;
End;

Procedure VFXMakeTempDirName;
Var TempBase, TimeStr: String;
    Hr, Mn, Sc, Sc100: Word; V: LongInt;
Begin
 TempBase := GetEnv('TEMP');
 If TempBase = '' Then TempBase := GetEnv('TMP');
 If TempBase = '' Then TempBase := 'C:\TEMP';
 GetTime(Hr, Mn, Sc, Sc100);
 V := LongInt(Hr) * 1000000 + LongInt(Mn) * 10000 +
      LongInt(Sc) * 100 + LongInt(Sc100);
 Str(V, TimeStr);
 VFX_TempDir := TempBase + '\vsdx_' + TimeStr;
End;

Function VFXCreateTempDir: Boolean;
Begin
 VFXCreateTempDir := False;
 {$I-} MkDir(VFX_TempDir); {$I+}
 If IOResult <> 0 Then Exit;
 VFXCreateTempDir := True;
End;

Function VFXExtractVSDX(Const VSDXPath: String): Boolean;
Begin
 { Built-in ZIP extraction via embedded CORAIL UNZIP (no external tools). }
 VFXExtractVSDX := CorailUnzipExtract(VSDXPath, VFX_TempDir);
End;

Procedure VFXCleanupRecursive(Const Dir: String);
Var SR: SearchRec; Full: String;
Begin
 FindFirst(Dir + '\*.*', AnyFile, SR);
 While DosError = 0 Do Begin
  If (SR.Name <> '.') And (SR.Name <> '..') Then Begin
   Full := Dir + '\' + SR.Name;
   If (SR.Attr And Directory) <> 0 Then
    VFXCleanupRecursive(Full)
   Else Begin
    {$I-} Assign(VFX_DummyFile, Full); Erase(VFX_DummyFile); {$I+}
    If IOResult <> 0 Then ;
   End;
  End;
  FindNext(SR);
 End;
 FindClose(SR);
 {$I-} RmDir(Dir); {$I+}
 If IOResult <> 0 Then ;
End;

Procedure VFXCleanupTempDir;
Begin
 If VFX_TempDir = '' Then Exit;
 VFXCleanupRecursive(VFX_TempDir);
End;

Procedure VFXResetShape(Var Sh: TShapeObject);
Var I: Integer;
Begin
 Sh.ShapeType := stNone;
 Sh.X1 := 0; Sh.Y1 := 0; Sh.X2 := 0; Sh.Y2 := 0;
 Sh.FillColor := White;
 Sh.LineColor := Black;
 Sh.LineWidth := 1;
 Sh.LineStyle := LINESTYLE_SOLID;
 Sh.LayerIndex := 1;
 Sh.GroupID := 0;
 Sh.Text := '';
 Sh.Selected := False;
 Sh.PointCount := 0;
 For I := 1 To MAX_POLYGON_POINTS Do Begin
  Sh.Points[I].X := 0; Sh.Points[I].Y := 0;
 End;
 Sh.ImagePath := '';
 Sh.ConnectStartShape := 0;
 Sh.ConnectEndShape := 0;
 Sh.ConnectStartAnchor := ANCHOR_NONE;
 Sh.ConnectEndAnchor := ANCHOR_NONE;
End;

Function VFXShortFileName(Const FullPath: String): String;
Var I: Integer; S: String;
Begin
 S := FullPath;
 For I := Length(S) DownTo 1 Do
  If (S[I] = '\') Or (S[I] = '/') Or (S[I] = ':') Then Begin
   Delete(S, 1, I);
   Break;
  End;
 VFXShortFileName := S;
End;

Procedure VFXGeneratePlaceholderShapes(Const FileLabel: String;
                                       WorkX1, WorkY1, WorkX2, WorkY2: Integer);
Var BoxW, BoxH, Margin, Cx, Cy: Integer;
Begin
 Margin := 20;
 BoxW := (WorkX2 - WorkX1) - 2 * Margin;
 BoxH := (WorkY2 - WorkY1) - 2 * Margin;
 If BoxW < 100 Then BoxW := 100;
 If BoxH < 60 Then BoxH := 60;
 If ShapeCount < MAX_SHAPES Then Begin
  Inc(ShapeCount); VFXResetShape(Shapes[ShapeCount]);
  Shapes[ShapeCount].ShapeType := stRectangle;
  Shapes[ShapeCount].X1 := WorkX1 + Margin;
  Shapes[ShapeCount].Y1 := WorkY1 + Margin;
  Shapes[ShapeCount].X2 := WorkX1 + Margin + BoxW;
  Shapes[ShapeCount].Y2 := WorkY1 + Margin + BoxH;
  Shapes[ShapeCount].FillColor := White;
  Shapes[ShapeCount].LineColor := LightGray;
 End;
 Cx := (WorkX1 + WorkX2) Div 2;
 Cy := (WorkY1 + WorkY2) Div 2;
 If ShapeCount < MAX_SHAPES Then Begin
  Inc(ShapeCount); VFXResetShape(Shapes[ShapeCount]);
  Shapes[ShapeCount].ShapeType := stRectangle;
  Shapes[ShapeCount].X1 := Cx - 160; Shapes[ShapeCount].Y1 := Cy - 30;
  Shapes[ShapeCount].X2 := Cx + 160; Shapes[ShapeCount].Y2 := Cy + 30;
  Shapes[ShapeCount].FillColor := LightCyan;
  Shapes[ShapeCount].LineColor := Blue;
  Shapes[ShapeCount].LineWidth := 2;
 End;
 If ShapeCount < MAX_SHAPES Then Begin
  Inc(ShapeCount); VFXResetShape(Shapes[ShapeCount]);
  Shapes[ShapeCount].ShapeType := stText;
  Shapes[ShapeCount].X1 := Cx - 152; Shapes[ShapeCount].Y1 := Cy - 12;
  Shapes[ShapeCount].X2 := Cx + 152; Shapes[ShapeCount].Y2 := Cy - 4;
  Shapes[ShapeCount].LineColor := Black;
  Shapes[ShapeCount].Text := Copy(FileLabel, 1, 40);
 End;
 If ShapeCount < MAX_SHAPES Then Begin
  Inc(ShapeCount); VFXResetShape(Shapes[ShapeCount]);
  Shapes[ShapeCount].ShapeType := stText;
  Shapes[ShapeCount].X1 := Cx - 152; Shapes[ShapeCount].Y1 := Cy + 4;
  Shapes[ShapeCount].X2 := Cx + 152; Shapes[ShapeCount].Y2 := Cy + 12;
  Shapes[ShapeCount].LineColor := DarkGray;
  Shapes[ShapeCount].Text := '(apercu - parseur binaire incomplet)';
 End;
End;

Procedure VFXParseShapesFromBuf(WorkX1, WorkY1, WorkX2, WorkY2: Integer);
Var
 P, EndOfShape, PgStart, PgEnd: LongInt;
 PinX, PinY, W, H, PageW, PageH: Real;
 Cx, Cy, Scale, ScaleX, ScaleY: Real;
 Sx1, Sy1, Sx2, Sy2, OffX, OffY, TxtX, TxtY: Integer;
 TxtContent: String;
 PalIdx: Integer;
 PaletteFill: Array[0..5] of Integer;
 NativeX1, TypeStr, FillStr, LineStr, LWStr, LSStr: String;
 TypeVal, ValCode: Integer;
Begin
 PaletteFill[0] := LightCyan;
 PaletteFill[1] := LightGreen;
 PaletteFill[2] := Yellow;
 PaletteFill[3] := LightRed;
 PaletteFill[4] := LightMagenta;
 PaletteFill[5] := White;
 PalIdx := 0;

 PageW := 0; PageH := 0;
 PgStart := VFXFindFrom('<PageSheet', 0);
 If PgStart >= 0 Then Begin
  PgEnd := VFXFindFrom('</PageSheet>', PgStart);
  If PgEnd < 0 Then PgEnd := VFX_BufLen;
  PageW := VFXStrToReal(VFXFindCellValue(PgStart, PgEnd, 'PageWidth'));
  PageH := VFXStrToReal(VFXFindCellValue(PgStart, PgEnd, 'PageHeight'));
 End;
 If PageW <= 0 Then PageW := 8.5;
 If PageH <= 0 Then PageH := 11.0;

 ScaleX := (WorkX2 - WorkX1) / PageW;
 ScaleY := (WorkY2 - WorkY1) / PageH;
 If ScaleX < ScaleY Then Scale := ScaleX * 0.92 Else Scale := ScaleY * 0.92;
 If Scale < 1 Then Scale := 1;

 OffX := WorkX1 + ((WorkX2 - WorkX1) - Round(PageW * Scale)) Div 2;
 OffY := WorkY1 + ((WorkY2 - WorkY1) - Round(PageH * Scale)) Div 2;
 If OffX < WorkX1 Then OffX := WorkX1;
 If OffY < WorkY1 Then OffY := WorkY1;

 If ShapeCount < MAX_SHAPES Then Begin
  Inc(ShapeCount); VFXResetShape(Shapes[ShapeCount]);
  Shapes[ShapeCount].ShapeType := stRectangle;
  Shapes[ShapeCount].X1 := OffX; Shapes[ShapeCount].Y1 := OffY;
  Shapes[ShapeCount].X2 := OffX + Round(PageW * Scale);
  Shapes[ShapeCount].Y2 := OffY + Round(PageH * Scale);
  Shapes[ShapeCount].FillColor := White;
  Shapes[ShapeCount].LineColor := LightGray;
  Shapes[ShapeCount].LineWidth := 1;
  Shapes[ShapeCount].LineStyle := LINESTYLE_SOLID;
 End;

 P := 0;
 Repeat
  P := VFXFindFrom('<Shape ', P);
  If P < 0 Then Break;
  EndOfShape := VFXFindFrom('</Shape>', P);
  If EndOfShape < 0 Then Break;
  TxtContent := VFXFindShapeText(P, EndOfShape);

  { Format natif (round-trip): X1/Y1/X2/Y2 + Type + couleurs en pixels }
  NativeX1 := VFXFindCellValue(P, EndOfShape, 'X1');
  If NativeX1 <> '' Then Begin
   If ShapeCount < MAX_SHAPES - 1 Then Begin
    Sx1 := Round(VFXStrToReal(NativeX1));
    Sy1 := Round(VFXStrToReal(VFXFindCellValue(P, EndOfShape, 'Y1')));
    Sx2 := Round(VFXStrToReal(VFXFindCellValue(P, EndOfShape, 'X2')));
    Sy2 := Round(VFXStrToReal(VFXFindCellValue(P, EndOfShape, 'Y2')));
    Inc(ShapeCount); VFXResetShape(Shapes[ShapeCount]);
    { Type de forme }
    Shapes[ShapeCount].ShapeType := stRectangle;
    TypeStr := VFXFindCellValue(P, EndOfShape, 'Type');
    If TypeStr <> '' Then Begin
     Val(TypeStr, TypeVal, ValCode);
     If (ValCode = 0) And (TypeVal >= 0) And (TypeVal <= 8) Then
      Shapes[ShapeCount].ShapeType := TShapeType(TypeVal);
    End;
    Shapes[ShapeCount].X1 := Sx1; Shapes[ShapeCount].Y1 := Sy1;
    Shapes[ShapeCount].X2 := Sx2; Shapes[ShapeCount].Y2 := Sy2;
    { Couleurs }
    FillStr := VFXFindCellValue(P, EndOfShape, 'FillColor');
    LineStr := VFXFindCellValue(P, EndOfShape, 'LineColor');
    LWStr   := VFXFindCellValue(P, EndOfShape, 'LineWidth');
    LSStr   := VFXFindCellValue(P, EndOfShape, 'LineStyle');
    Shapes[ShapeCount].FillColor := White;
    Shapes[ShapeCount].LineColor := Black;
    Shapes[ShapeCount].LineWidth := 1;
    Shapes[ShapeCount].LineStyle := LINESTYLE_SOLID;
    If FillStr <> '' Then Begin
     Val(FillStr, TypeVal, ValCode);
     If ValCode = 0 Then Shapes[ShapeCount].FillColor := TypeVal;
    End;
    If LineStr <> '' Then Begin
     Val(LineStr, TypeVal, ValCode);
     If ValCode = 0 Then Shapes[ShapeCount].LineColor := TypeVal;
    End;
    If LWStr <> '' Then Begin
     Val(LWStr, TypeVal, ValCode);
     If (ValCode = 0) And (TypeVal > 0) Then Shapes[ShapeCount].LineWidth := TypeVal;
    End;
    If LSStr <> '' Then Begin
     Val(LSStr, TypeVal, ValCode);
     If ValCode = 0 Then Shapes[ShapeCount].LineStyle := TypeVal;
    End;
    Shapes[ShapeCount].Text := Copy(TxtContent, 1, 80);
   End;
  End Else Begin
   { Format Visio canonique (PinX/PinY/Width/Height en unites de page) }
   PinX := VFXStrToReal(VFXFindCellValue(P, EndOfShape, 'PinX'));
   PinY := VFXStrToReal(VFXFindCellValue(P, EndOfShape, 'PinY'));
   W    := VFXStrToReal(VFXFindCellValue(P, EndOfShape, 'Width'));
   H    := VFXStrToReal(VFXFindCellValue(P, EndOfShape, 'Height'));

   If (W > 0) And (H > 0) And (ShapeCount < MAX_SHAPES - 1) Then Begin
    Cx := PinX;
    Cy := PageH - PinY;
    Sx1 := OffX + Round((Cx - W / 2) * Scale);
    Sy1 := OffY + Round((Cy - H / 2) * Scale);
    Sx2 := OffX + Round((Cx + W / 2) * Scale);
    Sy2 := OffY + Round((Cy + H / 2) * Scale);
    If Sx1 < WorkX1 Then Sx1 := WorkX1;
    If Sy1 < WorkY1 Then Sy1 := WorkY1;
    If Sx2 > WorkX2 Then Sx2 := WorkX2;
    If Sy2 > WorkY2 Then Sy2 := WorkY2;
    Inc(ShapeCount); VFXResetShape(Shapes[ShapeCount]);
    Shapes[ShapeCount].ShapeType := stRectangle;
    Shapes[ShapeCount].X1 := Sx1; Shapes[ShapeCount].Y1 := Sy1;
    Shapes[ShapeCount].X2 := Sx2; Shapes[ShapeCount].Y2 := Sy2;
    Shapes[ShapeCount].FillColor := PaletteFill[PalIdx mod 6];
    Shapes[ShapeCount].LineColor := Blue;
    Shapes[ShapeCount].LineWidth := 1;
    Shapes[ShapeCount].LineStyle := LINESTYLE_SOLID;
    Shapes[ShapeCount].Text := Copy(TxtContent, 1, 80);
    Inc(PalIdx);

    If (Length(TxtContent) > 0) And (ShapeCount < MAX_SHAPES) Then Begin
     TxtX := (Sx1 + Sx2) Div 2 - (Length(TxtContent) * 4);
     TxtY := (Sy1 + Sy2) Div 2 - 4;
     If TxtX < Sx1 + 2 Then TxtX := Sx1 + 2;
     If TxtY < Sy1 + 2 Then TxtY := Sy1 + 2;
     Inc(ShapeCount); VFXResetShape(Shapes[ShapeCount]);
     Shapes[ShapeCount].ShapeType := stText;
     Shapes[ShapeCount].X1 := TxtX; Shapes[ShapeCount].Y1 := TxtY;
     Shapes[ShapeCount].X2 := TxtX + Length(TxtContent) * 8;
     Shapes[ShapeCount].Y2 := TxtY + 8;
     Shapes[ShapeCount].LineColor := Black;
     Shapes[ShapeCount].FillColor := White;
     Shapes[ShapeCount].Text := Copy(TxtContent, 1, 80);
    End;
   End;
  End;
  P := EndOfShape + 8;
 Until P >= VFX_BufLen;
End;

{ Procedure pour parser un fichier VSD (format OLE binaire) }
Function ParseVSDFile(Const FileName: String): Boolean;
Var
 F: File;
 Header: TOLEHeader;
 Entry: TOLEDirectoryEntry;
 I, EntryIndex: Integer;
 SectorSize: Integer;
 EntryName: String;
 FoundVisioContent: Boolean;
Begin
 ParseVSDFile := False;
 FoundVisioContent := False;

 Assign(F, FileName);
 {$I-}
 Reset(F, 1);
 {$I+}
 If IOResult <> 0 Then Exit;

 { Lire l'en-tÃªte OLE }
 If Not ReadOLEHeader(F, Header) Then Begin
  Close(F);
  Exit;
 End;

 { Calculer la taille des secteurs }
 SectorSize := 1 shl Header.SectorShift;

 { Parcourir le rÃ©pertoire pour trouver les streams Visio }
 EntryIndex := 0;
 While EntryIndex < 32 do Begin { Limiter Ã  32 entrÃ©es pour la sÃ©curitÃ© }
  If ReadOLEDirectoryEntry(F, Header.FirstDirSector, EntryIndex, SectorSize, Entry) Then Begin
   EntryName := GetOLEEntryName(Entry);

   { Chercher les streams Visio connus }
   If (Pos('VisioDocument', EntryName) > 0) or
      (Pos('Contents', EntryName) > 0) or
      (Pos('Page', EntryName) > 0) Then Begin
    FoundVisioContent := True;
    { Note: L'implÃ©mentation complÃ¨te du parsing des donnÃ©es Visio }
    { nÃ©cessiterait de lire et interprÃ©ter le format binaire Visio }
    { qui est trÃ¨s complexe. Cette implÃ©mentation dÃ©tecte le fichier. }
   End;
  End;
  Inc(EntryIndex);
 End;

 Close(F);

 If FoundVisioContent Then Begin
  { Generer un apercu placeholder visuel - le format binaire Visio etant }
  { proprietaire et tres complexe, on signale au moins que le fichier a   }
  { ete charge avec succes.                                                }
  ShapeCount := 0;
  VFXGeneratePlaceholderShapes(VFXShortFileName(FileName),
                               80, WORK_AREA_TOP + 10,
                               ScreenWidth - 20, ScreenHeight - 30);
 End;

 ParseVSDFile := FoundVisioContent;
End;

{ Procedure pour parser un fichier VSDX (format XML compresse ZIP) }
{ Strategie: tar.exe (Windows 10+) extrait le ZIP -> on lit page1.xml }
{ -> on parse les <Shape> -> on genere des TShapeObject reels.        }
Function ParseVSDXFile(Const FileName: String): Boolean;
Var
 F: File;
 Buffer: Array[0..29] of Byte;
 BytesRead: Integer;
 LocalHeaderSig: LongInt;
 PageFile: String;
 WorkX1, WorkY1, WorkX2, WorkY2: Integer;
Begin
 ParseVSDXFile := False;

 Assign(F, FileName);
 {$I-} Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 BlockRead(F, Buffer, 30, BytesRead);
 Close(F);
 If BytesRead < 30 Then Exit;

 LocalHeaderSig := LongInt(Buffer[0]) Or (LongInt(Buffer[1]) shl 8) Or
                   (LongInt(Buffer[2]) shl 16) Or (LongInt(Buffer[3]) shl 24);
 If LocalHeaderSig <> $04034B50 Then Exit;

 WorkX1 := 80;
 WorkY1 := WORK_AREA_TOP + 10;
 WorkX2 := ScreenWidth - 20;
 WorkY2 := ScreenHeight - 30;

 VFXMakeTempDirName;
 If Not VFXCreateTempDir Then Begin
  ShapeCount := 0;
  VFXGeneratePlaceholderShapes(VFXShortFileName(FileName),
                               WorkX1, WorkY1, WorkX2, WorkY2);
  ParseVSDXFile := True;
  Exit;
 End;

 If VFXExtractVSDX(FileName) Then Begin
  PageFile := VFX_TempDir + '\visio\pages\page1.xml';
  If VFXReadFileToBuf(PageFile) Then Begin
   ShapeCount := 0;
   VFXParseShapesFromBuf(WorkX1, WorkY1, WorkX2, WorkY2);
  End Else Begin
   ShapeCount := 0;
   VFXGeneratePlaceholderShapes(VFXShortFileName(FileName),
                                WorkX1, WorkY1, WorkX2, WorkY2);
  End;
 End Else Begin
  ShapeCount := 0;
  VFXGeneratePlaceholderShapes(VFXShortFileName(FileName),
                               WorkX1, WorkY1, WorkX2, WorkY2);
 End;

 VFXCleanupTempDir;
 ParseVSDXFile := True;
End;

{ Fonction principale pour ouvrir un fichier Visio }
Function LoadVisioFile(Const FileName: String): Boolean;
Var
 FileFormat: Integer;
Begin
 LoadVisioFile := False;

 { DÃ©tecter le format du fichier }
 FileFormat := DetectVisioFormat(FileName);

 Case FileFormat of
  VISIO_FORMAT_VSD: Begin
   LoadVisioFile := ParseVSDFile(FileName);
  End;
  VISIO_FORMAT_VSDX: Begin
   LoadVisioFile := ParseVSDXFile(FileName);
  End;
 End;
End;

{ ============================================================================ }
{ === FIN DES FONCTIONS DE PARSING VISIO === }
{ ============================================================================ }

{ ============================================================================ }
{ === FONCTIONS D'ECRITURE DES FICHIERS VISIO VSD/VSDX === }
{ ============================================================================ }

{ Fonction pour convertir une couleur Pascal en couleur Visio (BGR) }
Function PascalColorToVisioColor(PascalColor: Integer): LongInt;
Begin
 Case PascalColor of
  0: PascalColorToVisioColor := $000000;  { Noir }
  1: PascalColorToVisioColor := $FF0000;  { Bleu }
  2: PascalColorToVisioColor := $00FF00;  { Vert }
  3: PascalColorToVisioColor := $FFFF00;  { Cyan }
  4: PascalColorToVisioColor := $0000FF;  { Rouge }
  5: PascalColorToVisioColor := $FF00FF;  { Magenta }
  6: PascalColorToVisioColor := $00FFFF;  { Marron/Jaune foncÃ© }
  7: PascalColorToVisioColor := $C0C0C0;  { Gris clair }
  8: PascalColorToVisioColor := $808080;  { Gris foncÃ© }
  9: PascalColorToVisioColor := $FF8080;  { Bleu clair }
  10: PascalColorToVisioColor := $80FF80; { Vert clair }
  11: PascalColorToVisioColor := $FFFF80; { Cyan clair }
  12: PascalColorToVisioColor := $8080FF; { Rouge clair }
  13: PascalColorToVisioColor := $FF80FF; { Magenta clair }
  14: PascalColorToVisioColor := $00FFFF; { Jaune }
  15: PascalColorToVisioColor := $FFFFFF; { Blanc }
 Else
  PascalColorToVisioColor := $000000;     { Noir par dÃ©faut }
 End;
End;

{ Fonction pour convertir TShapeType en type de forme Visio }
Function TShapeTypeToVisioShapeType(ST: TShapeType): Integer;
Begin
 Case ST of
  stRectangle: TShapeTypeToVisioShapeType := VISIO_SHAPE_RECTANGLE;
  stEllipse: TShapeTypeToVisioShapeType := VISIO_SHAPE_ELLIPSE;
  stLine: TShapeTypeToVisioShapeType := VISIO_SHAPE_LINE;
  stPolygon: TShapeTypeToVisioShapeType := VISIO_SHAPE_POLYLINE;
  stConnector: TShapeTypeToVisioShapeType := VISIO_SHAPE_CONNECTOR;
  stText: TShapeTypeToVisioShapeType := VISIO_SHAPE_TEXT;
 Else
  TShapeTypeToVisioShapeType := VISIO_SHAPE_RECTANGLE;
 End;
End;

{ ProcÃ©dure pour convertir TShapeObject en TVisioShape }
Procedure ShapeObjectToVisioShape(Const Shape: TShapeObject; Var VSh: TVisioShape);
Begin
 VSh.ShapeType := TShapeTypeToVisioShapeType(Shape.ShapeType);
 VSh.X := Shape.X1;
 VSh.Y := Shape.Y1;
 VSh.Width := Shape.X2 - Shape.X1;
 VSh.Height := Shape.Y2 - Shape.Y1;
 VSh.Angle := 0;
 VSh.FillColor := PascalColorToVisioColor(Shape.FillColor);
 VSh.LineColor := PascalColorToVisioColor(Shape.LineColor);
 VSh.LineWeight := Shape.LineWidth;
 VSh.Text := Shape.Text;
 VSh.ParentID := Shape.GroupID;
End;

{ ProcÃ©dure pour initialiser l'en-tÃªte OLE avec des valeurs par dÃ©faut }
Procedure InitOLEHeader(Var Header: TOLEHeader);
Var
 I: Integer;
Begin
 { Signature OLE }
 Header.Signature[0] := $D0;
 Header.Signature[1] := $CF;
 Header.Signature[2] := $11;
 Header.Signature[3] := $E0;
 Header.Signature[4] := $A1;
 Header.Signature[5] := $B6;
 Header.Signature[6] := $1A;
 Header.Signature[7] := $E1;

 { CLSID Visio (simplifiÃ©) }
 For I := 0 to 15 do Header.CLSID[I] := 0;

 Header.MinorVersion := $003E;
 Header.MajorVersion := $0003;
 Header.ByteOrder := $FFFE;        { Little-endian }
 Header.SectorShift := 9;          { 512 octets par secteur }
 Header.MiniSectorShift := 6;      { 64 octets par mini-secteur }

 For I := 0 to 5 do Header.Reserved[I] := 0;

 Header.TotalSectors := 0;
 Header.FirstDirSector := 0;
 Header.TransactionSig := 0;
 Header.MiniStreamCutoff := 4096;
 Header.FirstMiniFATSector := -2;  { ENDOFCHAIN }
 Header.NumMiniFATSectors := 0;
 Header.FirstDIFATSector := -2;    { ENDOFCHAIN }
 Header.NumDIFATSectors := 0;

 For I := 0 to 108 do Header.DIFAT[I] := -1;  { FREESECT }
End;

{ ProcÃ©dure pour initialiser une entrÃ©e de rÃ©pertoire OLE }
Procedure InitOLEDirectoryEntry(Var Entry: TOLEDirectoryEntry;
                                  Const Name: String; ObjType: Byte);
Var
 I: Integer;
 NameLen: Integer;
Begin
 { Effacer l'entrÃ©e }
 For I := 0 to 63 do Entry.EntryName[I] := 0;

 { Copier le nom en UTF-16 (simplifiÃ©: ASCII seulement) }
 NameLen := Length(Name);
 If NameLen > 31 Then NameLen := 31;
 For I := 1 to NameLen do Begin
  Entry.EntryName[(I-1) * 2] := Ord(Name[I]);
  Entry.EntryName[(I-1) * 2 + 1] := 0;
 End;

 Entry.NameLength := (NameLen + 1) * 2;  { Inclure le null terminator }
 Entry.ObjectType := ObjType;
 Entry.ColorFlag := 1;  { Rouge dans l'arbre rouge-noir }
 Entry.LeftSiblingID := -1;   { NOSTREAM }
 Entry.RightSiblingID := -1;  { NOSTREAM }
 Entry.ChildID := -1;         { NOSTREAM }

 For I := 0 to 15 do Entry.CLSID[I] := 0;
 Entry.StateBits := 0;
 For I := 0 to 7 do Begin
  Entry.CreationTime[I] := 0;
  Entry.ModifiedTime[I] := 0;
 End;
 Entry.StartSector := 0;
 For I := 0 to 7 do Entry.StreamSize[I] := 0;
End;

{ Fonction pour Ã©crire un fichier VSD (format OLE binaire) }
Function WriteVSDFile(Const FileName: String): Boolean;
Var
 F: File;
 Header: TOLEHeader;
 RootEntry, VisioDocEntry, ContentsEntry: TOLEDirectoryEntry;
 FAT: Array[0..127] of LongInt;
 I: Integer;
 BytesWritten: Integer;
 ShapeData: Array[0..4095] of Byte;
 DataSize: Integer;
 VShape: TVisioShape;
 DataOffset: Integer;
Begin
 WriteVSDFile := False;

 Assign(F, FileName);
 {$I-}
 Rewrite(F, 1);
 {$I+}
 If IOResult <> 0 Then Exit;

 { Initialiser l'en-tÃªte OLE }
 InitOLEHeader(Header);
 Header.FirstDirSector := 1;
 Header.TotalSectors := 4;
 Header.DIFAT[0] := 0;  { FAT dans le secteur 0 }

 { Ã‰crire l'en-tÃªte (512 octets) }
 BlockWrite(F, Header, 512, BytesWritten);
 If BytesWritten < 512 Then Begin
  Close(F);
  Exit;
 End;

 { Initialiser et Ã©crire le FAT (secteur 0) }
 For I := 0 to 127 do FAT[I] := -1;  { FREESECT }
 FAT[0] := -3;  { FATSECT - ce secteur contient le FAT }
 FAT[1] := -2;  { ENDOFCHAIN - fin de la chaÃ®ne du rÃ©pertoire }
 FAT[2] := -2;  { ENDOFCHAIN - fin de VisioDocument }
 FAT[3] := -2;  { ENDOFCHAIN - fin de Contents }

 BlockWrite(F, FAT, 512, BytesWritten);
 If BytesWritten < 512 Then Begin
  Close(F);
  Exit;
 End;

 { CrÃ©er les entrÃ©es du rÃ©pertoire (secteur 1) }
 { EntrÃ©e 0: Root Entry }
 InitOLEDirectoryEntry(RootEntry, 'Root Entry', 5);  { 5 = Root Storage }
 RootEntry.ChildID := 1;

 { EntrÃ©e 1: VisioDocument }
 InitOLEDirectoryEntry(VisioDocEntry, 'VisioDocument', 1);  { 1 = Storage }
 VisioDocEntry.RightSiblingID := 2;
 VisioDocEntry.StartSector := 2;

 { EntrÃ©e 2: Contents }
 InitOLEDirectoryEntry(ContentsEntry, 'Contents', 2);  { 2 = Stream }
 ContentsEntry.StartSector := 3;

 { Ã‰crire les entrÃ©es du rÃ©pertoire }
 BlockWrite(F, RootEntry, 128, BytesWritten);
 BlockWrite(F, VisioDocEntry, 128, BytesWritten);
 BlockWrite(F, ContentsEntry, 128, BytesWritten);

 { Remplir le reste du secteur avec des entrÃ©es vides }
 For I := 0 to 127 do ShapeData[I] := 0;
 BlockWrite(F, ShapeData, 128, BytesWritten);

 { Ã‰crire le stream VisioDocument (secteur 2) - en-tÃªte Visio simplifiÃ© }
 For I := 0 to 511 do ShapeData[I] := 0;
 { Signature Visio simplifiÃ©e }
 ShapeData[0] := Ord('V');
 ShapeData[1] := Ord('I');
 ShapeData[2] := Ord('S');
 ShapeData[3] := Ord('I');
 ShapeData[4] := Ord('O');
 ShapeData[5] := 1;  { Version }
 ShapeData[6] := Lo(ShapeCount);
 ShapeData[7] := Hi(ShapeCount);

 BlockWrite(F, ShapeData, 512, BytesWritten);

 { Ã‰crire le stream Contents (secteur 3) - donnÃ©es des formes }
 For I := 0 to 4095 do ShapeData[I] := 0;
 DataOffset := 0;

 For I := 1 to ShapeCount do Begin
  If DataOffset + 64 > 512 Then Break;  { Limite de taille du secteur }

  ShapeObjectToVisioShape(Shapes[I], VShape);

  { Ã‰crire les donnÃ©es de la forme de maniÃ¨re simplifiÃ©e }
  { Type de forme (1 octet) }
  ShapeData[DataOffset] := VShape.ShapeType;
  Inc(DataOffset);

  { Position X (2 octets) }
  ShapeData[DataOffset] := Lo(Round(VShape.X));
  ShapeData[DataOffset + 1] := Hi(Round(VShape.X));
  Inc(DataOffset, 2);

  { Position Y (2 octets) }
  ShapeData[DataOffset] := Lo(Round(VShape.Y));
  ShapeData[DataOffset + 1] := Hi(Round(VShape.Y));
  Inc(DataOffset, 2);

  { Largeur (2 octets) }
  ShapeData[DataOffset] := Lo(Round(VShape.Width));
  ShapeData[DataOffset + 1] := Hi(Round(VShape.Width));
  Inc(DataOffset, 2);

  { Hauteur (2 octets) }
  ShapeData[DataOffset] := Lo(Round(VShape.Height));
  ShapeData[DataOffset + 1] := Hi(Round(VShape.Height));
  Inc(DataOffset, 2);

  { Couleur de remplissage (4 octets) }
  ShapeData[DataOffset] := VShape.FillColor and $FF;
  ShapeData[DataOffset + 1] := (VShape.FillColor shr 8) and $FF;
  ShapeData[DataOffset + 2] := (VShape.FillColor shr 16) and $FF;
  ShapeData[DataOffset + 3] := 0;
  Inc(DataOffset, 4);

  { Couleur de ligne (4 octets) }
  ShapeData[DataOffset] := VShape.LineColor and $FF;
  ShapeData[DataOffset + 1] := (VShape.LineColor shr 8) and $FF;
  ShapeData[DataOffset + 2] := (VShape.LineColor shr 16) and $FF;
  ShapeData[DataOffset + 3] := 0;
  Inc(DataOffset, 4);

  { Ã‰paisseur de ligne (1 octet) }
  ShapeData[DataOffset] := Round(VShape.LineWeight);
  Inc(DataOffset);

  { Longueur du texte (1 octet) + texte (jusqu'Ã  40 caractÃ¨res) }
  DataSize := Length(VShape.Text);
  If DataSize > 40 Then DataSize := 40;
  ShapeData[DataOffset] := DataSize;
  Inc(DataOffset);
  Move(VShape.Text[1], ShapeData[DataOffset], DataSize);
  Inc(DataOffset, 40);
 End;

 { Marquer la fin des donnÃ©es }
 ShapeData[DataOffset] := $FF;

 BlockWrite(F, ShapeData, 512, BytesWritten);

 Close(F);
 WriteVSDFile := True;
End;

{ Fonction pour calculer le CRC32 standard (ZIP / PKZIP) }
Function CalcCRC32(Const Data; Size: Integer): LongInt;
Var
 I: Integer;
 CRC: LongInt;
 P: ^Byte;
Begin
 InitCRC32;
 CRC := LongInt($FFFFFFFF);
 P := @Data;
 For I := 0 to Size - 1 do Begin
  CRC := CRC32Value(CRC, P^);
  Inc(P);
 End;
 CalcCRC32 := CRC xor LongInt($FFFFFFFF);
End;

{ Fonction pour ecrire un fichier VSDX (format ZIP avec XML canonique Visio) }
Function WriteVSDXFile(Const FileName: String): Boolean;
Const
 EntryName    = 'visio/pages/page1.xml';
 EntryNameLen = 21;
Var
 F: File;
 LocalHeader: Array[0..29] of Byte;
 CentralDir: Array[0..45] of Byte;
 EndRecord: Array[0..21] of Byte;
 BytesWritten: Integer;
 CentralDirOffset, CDirSize: LongInt;
 XMLSize: LongInt;
 CRC: LongInt;
 ShapeIndex: Integer;
 EName: String;
 Sh: TShapeObject;
 CXf, CYf, PinX, PinY: Real;
 Wv, Hv: Integer;
 PageW, PageH: LongInt;

 Function INum(N: LongInt): String;
 Var S: String; Begin Str(N, S); INum := S; End;

 Function FNum(R: Real): String;
 Var S: String; Begin Str(R:0:2, S); FNum := S; End;

 Function XmlEscape(Const S: String): String;
 Var II: Integer; R: String;
 Begin
  R := '';
  For II := 1 To Length(S) Do
   Case S[II] Of
    '<' : R := R + '&lt;';
    '>' : R := R + '&gt;';
    '&' : R := R + '&amp;';
    '''': R := R + '&apos;';
    '"' : R := R + '&quot;';
   Else
    If (Ord(S[II]) >= 32) And (Ord(S[II]) < 127) Then R := R + S[II];
   End;
  XmlEscape := R;
 End;

 Procedure EmitS(Const S: String);
 Var II, Wrt: Integer;
 Begin
  If Length(S) = 0 Then Exit;
  BlockWrite(F, S[1], Length(S), Wrt);
  For II := 1 To Length(S) Do CRC := CRC32Value(CRC, Byte(S[II]));
  Inc(XMLSize, Length(S));
 End;

Begin
 WriteVSDXFile := False;
 InitCRC32;

 Assign(F, FileName);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Exit;

 PageW := ScreenWidth;  If PageW < 100 Then PageW := 1024;
 PageH := ScreenHeight; If PageH < 100 Then PageH := 768;
 EName := EntryName;

 { Reserver l'espace du local header (sera reecrit a la fin avec CRC/Size) }
 FillChar(LocalHeader, SizeOf(LocalHeader), 0);
 BlockWrite(F, LocalHeader, 30, BytesWritten);
 BlockWrite(F, EName[1], EntryNameLen, BytesWritten);

 { Generer le XML en streaming, accumuler CRC32 et taille }
 XMLSize := 0;
 CRC := LongInt($FFFFFFFF);

 EmitS('<?xml version="1.0" encoding="UTF-8"?>'#13#10);
 EmitS('<PageContents>'#13#10);
 EmitS(' <PageSheet>'#13#10);
 EmitS('  <Cell N=''PageWidth'' V='''+INum(PageW)+'''/>'#13#10);
 EmitS('  <Cell N=''PageHeight'' V='''+INum(PageH)+'''/>'#13#10);
 EmitS(' </PageSheet>'#13#10);
 EmitS(' <Shapes>'#13#10);

 For ShapeIndex := 1 To ShapeCount Do Begin
  Sh := Shapes[ShapeIndex];
  CXf := (Sh.X1 + Sh.X2) / 2;
  CYf := (Sh.Y1 + Sh.Y2) / 2;
  Wv := Sh.X2 - Sh.X1; If Wv < 0 Then Wv := -Wv;
  Hv := Sh.Y2 - Sh.Y1; If Hv < 0 Then Hv := -Hv;
  PinX := CXf;
  PinY := PageH - CYf;

  EmitS(' <Shape ID='''+INum(ShapeIndex)+'''>'#13#10);
  EmitS('  <Cell N=''Type'' V='''+INum(Ord(Sh.ShapeType))+'''/>'#13#10);
  EmitS('  <Cell N=''PinX'' V='''+FNum(PinX)+'''/>'#13#10);
  EmitS('  <Cell N=''PinY'' V='''+FNum(PinY)+'''/>'#13#10);
  EmitS('  <Cell N=''Width'' V='''+INum(Wv)+'''/>'#13#10);
  EmitS('  <Cell N=''Height'' V='''+INum(Hv)+'''/>'#13#10);
  EmitS('  <Cell N=''X1'' V='''+INum(Sh.X1)+'''/>'#13#10);
  EmitS('  <Cell N=''Y1'' V='''+INum(Sh.Y1)+'''/>'#13#10);
  EmitS('  <Cell N=''X2'' V='''+INum(Sh.X2)+'''/>'#13#10);
  EmitS('  <Cell N=''Y2'' V='''+INum(Sh.Y2)+'''/>'#13#10);
  EmitS('  <Cell N=''FillColor'' V='''+INum(Sh.FillColor)+'''/>'#13#10);
  EmitS('  <Cell N=''LineColor'' V='''+INum(Sh.LineColor)+'''/>'#13#10);
  EmitS('  <Cell N=''LineWidth'' V='''+INum(Sh.LineWidth)+'''/>'#13#10);
  EmitS('  <Cell N=''LineStyle'' V='''+INum(Sh.LineStyle)+'''/>'#13#10);
  If Length(Sh.Text) > 0 Then
   EmitS('  <Text>'+XmlEscape(Sh.Text)+'</Text>'#13#10);
  EmitS(' </Shape>'#13#10);
 End;

 EmitS(' </Shapes>'#13#10);
 EmitS('</PageContents>'#13#10);

 CRC := CRC Xor LongInt($FFFFFFFF);
 CentralDirOffset := 30 + EntryNameLen + XMLSize;

 { === Local file header (definitif) === }
 LocalHeader[0] := $50; LocalHeader[1] := $4B;
 LocalHeader[2] := $03; LocalHeader[3] := $04;
 LocalHeader[4] := 20;  LocalHeader[5] := 0;
 LocalHeader[6] := 0;   LocalHeader[7] := 0;
 LocalHeader[8] := 0;   LocalHeader[9] := 0;
 LocalHeader[10] := 0;  LocalHeader[11] := 0;
 LocalHeader[12] := 0;  LocalHeader[13] := 0;
 LocalHeader[14] := CRC And $FF;
 LocalHeader[15] := (CRC Shr 8) And $FF;
 LocalHeader[16] := (CRC Shr 16) And $FF;
 LocalHeader[17] := (CRC Shr 24) And $FF;
 LocalHeader[18] := XMLSize And $FF;
 LocalHeader[19] := (XMLSize Shr 8) And $FF;
 LocalHeader[20] := (XMLSize Shr 16) And $FF;
 LocalHeader[21] := (XMLSize Shr 24) And $FF;
 LocalHeader[22] := XMLSize And $FF;
 LocalHeader[23] := (XMLSize Shr 8) And $FF;
 LocalHeader[24] := (XMLSize Shr 16) And $FF;
 LocalHeader[25] := (XMLSize Shr 24) And $FF;
 LocalHeader[26] := EntryNameLen;
 LocalHeader[27] := 0;
 LocalHeader[28] := 0;  LocalHeader[29] := 0;

 { === Central directory entry === }
 FillChar(CentralDir, SizeOf(CentralDir), 0);
 CentralDir[0] := $50; CentralDir[1] := $4B;
 CentralDir[2] := $01; CentralDir[3] := $02;
 CentralDir[4] := 20;  CentralDir[5] := 0;
 CentralDir[6] := 20;  CentralDir[7] := 0;
 CentralDir[16] := CRC And $FF;
 CentralDir[17] := (CRC Shr 8) And $FF;
 CentralDir[18] := (CRC Shr 16) And $FF;
 CentralDir[19] := (CRC Shr 24) And $FF;
 CentralDir[20] := XMLSize And $FF;
 CentralDir[21] := (XMLSize Shr 8) And $FF;
 CentralDir[22] := (XMLSize Shr 16) And $FF;
 CentralDir[23] := (XMLSize Shr 24) And $FF;
 CentralDir[24] := XMLSize And $FF;
 CentralDir[25] := (XMLSize Shr 8) And $FF;
 CentralDir[26] := (XMLSize Shr 16) And $FF;
 CentralDir[27] := (XMLSize Shr 24) And $FF;
 CentralDir[28] := EntryNameLen;
 CentralDir[29] := 0;

 BlockWrite(F, CentralDir, 46, BytesWritten);
 BlockWrite(F, EName[1], EntryNameLen, BytesWritten);

 { === End of central directory record === }
 CDirSize := 46 + EntryNameLen;
 FillChar(EndRecord, SizeOf(EndRecord), 0);
 EndRecord[0] := $50; EndRecord[1] := $4B;
 EndRecord[2] := $05; EndRecord[3] := $06;
 EndRecord[8] := 1; EndRecord[10] := 1;
 EndRecord[12] := CDirSize And $FF;
 EndRecord[13] := (CDirSize Shr 8) And $FF;
 EndRecord[14] := (CDirSize Shr 16) And $FF;
 EndRecord[15] := (CDirSize Shr 24) And $FF;
 EndRecord[16] := CentralDirOffset And $FF;
 EndRecord[17] := (CentralDirOffset Shr 8) And $FF;
 EndRecord[18] := (CentralDirOffset Shr 16) And $FF;
 EndRecord[19] := (CentralDirOffset Shr 24) And $FF;

 BlockWrite(F, EndRecord, 22, BytesWritten);

 { Retour au debut, ecrire le local header definitif (avec CRC/Size corrects) }
 Seek(F, 0);
 BlockWrite(F, LocalHeader, 30, BytesWritten);

 Close(F);
 WriteVSDXFile := True;
End;

{ Fonction pour dÃ©terminer le format Ã  partir de l'extension du fichier }
Function GetVisioFormatFromExtension(Const FileName: String): Integer;
Var
 Ext: String;
 I: Integer;
Begin
 GetVisioFormatFromExtension := VISIO_FORMAT_UNKNOWN;

 { Trouver l'extension }
 Ext := '';
 For I := Length(FileName) downto 1 do Begin
  If FileName[I] = '.' Then Begin
   Ext := Copy(FileName, I, Length(FileName) - I + 1);
   Break;
  End;
 End;

 { Convertir en minuscules }
 For I := 1 to Length(Ext) do Begin
  If (Ext[I] >= 'A') and (Ext[I] <= 'Z') Then
   Ext[I] := Chr(Ord(Ext[I]) + 32);
 End;

 { DÃ©terminer le format }
 If (Ext = '.vsd') or (Ext = '.vss') or (Ext = '.vst') Then
  GetVisioFormatFromExtension := VISIO_FORMAT_VSD
 Else If (Ext = '.vsdx') or (Ext = '.vssx') or (Ext = '.vstx') Then
  GetVisioFormatFromExtension := VISIO_FORMAT_VSDX;
End;

{ Fonction principale pour sauvegarder un fichier Visio }
Function SaveVisioFile(Const FileName: String; FileFormat: Integer): Boolean;
Begin
 SaveVisioFile := False;

 { Si le format n'est pas spÃ©cifiÃ©, le dÃ©tecter depuis l'extension }
 If FileFormat = VISIO_FORMAT_UNKNOWN Then
  FileFormat := GetVisioFormatFromExtension(FileName);

 { Si toujours inconnu, utiliser VSDX par dÃ©faut (format moderne) }
 If FileFormat = VISIO_FORMAT_UNKNOWN Then
  FileFormat := VISIO_FORMAT_VSDX;

 Case FileFormat of
  VISIO_FORMAT_VSD: Begin
   SaveVisioFile := WriteVSDFile(FileName);
  End;
  VISIO_FORMAT_VSDX: Begin
   SaveVisioFile := WriteVSDXFile(FileName);
  End;
 End;
End;

{ ============================================================================ }
{ === FIN DES FONCTIONS D'ECRITURE VISIO === }
{ ============================================================================ }

{ ============================================================================ }
{ === FONCTIONS DE GESTION DES STENCILS ET MASTERS VISIO === }
{ ============================================================================ }

{ ProcÃ©dure pour initialiser un Master vide }
Procedure InitMaster(Var Master: TVisioMaster);
Var
 I: Integer;
Begin
 Master.ID := 0;
 Master.Name := '';
 Master.UniqueID := '';
 Master.IconIndex := 0;
 Master.BaseShape.ID := 0;
 Master.BaseShape.ShapeType := VISIO_SHAPE_RECTANGLE;
 Master.BaseShape.X := 0;
 Master.BaseShape.Y := 0;
 Master.BaseShape.Width := 100;
 Master.BaseShape.Height := 100;
 Master.BaseShape.Angle := 0;
 Master.BaseShape.FillColor := $FFFFFF;
 Master.BaseShape.LineColor := $000000;
 Master.BaseShape.LineWeight := 1;
 Master.BaseShape.Text := '';
 Master.BaseShape.ParentID := 0;
 Master.Width := 100;
 Master.Height := 100;
 Master.OffsetX := 50;
 Master.OffsetY := 50;
 Master.IsGroup := False;
 Master.SubShapeCount := 0;
 Master.ConnectionPointCount := 0;
 For I := 1 to 8 do Begin
  Master.ConnectionPoints[I].X := 0;
  Master.ConnectionPoints[I].Y := 0;
  Master.ConnectionPoints[I].DirX := 0;
  Master.ConnectionPoints[I].DirY := 0;
 End;
End;

{ ProcÃ©dure pour initialiser un Stencil vide }
Procedure InitStencil(Var Stencil: TVisioStencil);
Var
 I: Integer;
Begin
 Stencil.Name := '';
 Stencil.FilePath := '';
 Stencil.FileFormat := VISIO_STENCIL_FORMAT_VSSX;
 Stencil.MasterCount := 0;
 Stencil.IsModified := False;
 Stencil.IsReadOnly := False;
 For I := 1 to MAX_MASTERS do
  InitMaster(Stencil.Masters[I]);
End;

{ Fonction pour gÃ©nÃ©rer un GUID simplifiÃ© }
Function GenerateSimpleGUID: String;
Var
 I: Integer;
 S: String;
 HexChars: String;
Begin
 HexChars := '0123456789ABCDEF';
 S := '';
 For I := 1 to 32 do Begin
  S := S + HexChars[Random(16) + 1];
  If (I = 8) or (I = 12) or (I = 16) or (I = 20) Then
   S := S + '-';
 End;
 GenerateSimpleGUID := S;
End;

{ Fonction pour ajouter un Master Ã  un Stencil }
Function AddMasterToStencil(Var Stencil: TVisioStencil; Const Master: TVisioMaster): Boolean;
Begin
 AddMasterToStencil := False;
 If Stencil.MasterCount >= MAX_MASTERS Then Exit;

 Inc(Stencil.MasterCount);
 Stencil.Masters[Stencil.MasterCount] := Master;
 Stencil.Masters[Stencil.MasterCount].ID := NextMasterID;
 Inc(NextMasterID);
 Stencil.IsModified := True;
 AddMasterToStencil := True;
End;

{ Fonction pour crÃ©er un Master Ã  partir d'une TShapeObject }
Function CreateMasterFromShape(Const Shape: TShapeObject; Const MasterName: String): TVisioMaster;
Var
 Master: TVisioMaster;
Begin
 InitMaster(Master);
 Master.ID := NextMasterID;
 Inc(NextMasterID);
 Master.Name := MasterName;
 Master.UniqueID := GenerateSimpleGUID;

 { Convertir les propriÃ©tÃ©s de la forme }
 Master.BaseShape.ShapeType := TShapeTypeToVisioShapeType(Shape.ShapeType);
 Master.BaseShape.X := 0;
 Master.BaseShape.Y := 0;
 Master.BaseShape.Width := Shape.X2 - Shape.X1;
 Master.BaseShape.Height := Shape.Y2 - Shape.Y1;
 Master.BaseShape.Angle := 0;
 Master.BaseShape.FillColor := PascalColorToVisioColor(Shape.FillColor);
 Master.BaseShape.LineColor := PascalColorToVisioColor(Shape.LineColor);
 Master.BaseShape.LineWeight := Shape.LineWidth;
 Master.BaseShape.Text := Shape.Text;

 Master.Width := Master.BaseShape.Width;
 Master.Height := Master.BaseShape.Height;
 Master.OffsetX := Master.Width / 2;
 Master.OffsetY := Master.Height / 2;

 { Ajouter les points de connexion par dÃ©faut (4 cÃ´tÃ©s) }
 Master.ConnectionPointCount := 4;
 { Haut }
 Master.ConnectionPoints[1].X := Master.Width / 2;
 Master.ConnectionPoints[1].Y := 0;
 Master.ConnectionPoints[1].DirX := 0;
 Master.ConnectionPoints[1].DirY := -1;
 { Droite }
 Master.ConnectionPoints[2].X := Master.Width;
 Master.ConnectionPoints[2].Y := Master.Height / 2;
 Master.ConnectionPoints[2].DirX := 1;
 Master.ConnectionPoints[2].DirY := 0;
 { Bas }
 Master.ConnectionPoints[3].X := Master.Width / 2;
 Master.ConnectionPoints[3].Y := Master.Height;
 Master.ConnectionPoints[3].DirX := 0;
 Master.ConnectionPoints[3].DirY := 1;
 { Gauche }
 Master.ConnectionPoints[4].X := 0;
 Master.ConnectionPoints[4].Y := Master.Height / 2;
 Master.ConnectionPoints[4].DirX := -1;
 Master.ConnectionPoints[4].DirY := 0;

 CreateMasterFromShape := Master;
End;

{ ProcÃ©dure pour crÃ©er une TShapeObject Ã  partir d'un Master }
Procedure CreateShapeFromMaster(Const Master: TVisioMaster; X, Y: Integer; Var Shape: TShapeObject);
Begin
 { Initialiser la forme }
 Shape.ShapeType := stNone;
 Case Master.BaseShape.ShapeType of
  VISIO_SHAPE_RECTANGLE: Shape.ShapeType := stRectangle;
  VISIO_SHAPE_ELLIPSE: Shape.ShapeType := stEllipse;
  VISIO_SHAPE_LINE: Shape.ShapeType := stLine;
  VISIO_SHAPE_POLYLINE: Shape.ShapeType := stPolygon;
  VISIO_SHAPE_CONNECTOR: Shape.ShapeType := stConnector;
  VISIO_SHAPE_TEXT: Shape.ShapeType := stText;
 Else
  Shape.ShapeType := stRectangle;
 End;

 { Positionner la forme avec le point d'insertion centrÃ© }
 Shape.X1 := X - Round(Master.OffsetX);
 Shape.Y1 := Y - Round(Master.OffsetY);
 Shape.X2 := Shape.X1 + Round(Master.Width);
 Shape.Y2 := Shape.Y1 + Round(Master.Height);

 { Convertir les couleurs de Visio vers Pascal }
 Shape.FillColor := VisioColorToPascalColor(Master.BaseShape.FillColor);
 Shape.LineColor := VisioColorToPascalColor(Master.BaseShape.LineColor);
 Shape.LineWidth := Round(Master.BaseShape.LineWeight);
 Shape.LineStyle := 0;  { Solide }
 Shape.LayerIndex := 1;
 Shape.GroupID := 0;
 Shape.Text := Master.BaseShape.Text;
 Shape.Selected := False;
 Shape.PointCount := 0;
 Shape.ImagePath := '';
 Shape.ConnectStartShape := 0;
 Shape.ConnectEndShape := 0;
 Shape.ConnectStartAnchor := 0;
 Shape.ConnectEndAnchor := 0;
End;

{ Fonction pour rechercher un Master par son nom dans un Stencil }
Function GetMasterByName(Const Stencil: TVisioStencil; Const MasterName: String): Integer;
Var
 I: Integer;
Begin
 GetMasterByName := 0;
 For I := 1 to Stencil.MasterCount do Begin
  If Stencil.Masters[I].Name = MasterName Then Begin
   GetMasterByName := I;
   Exit;
  End;
 End;
End;

{ Fonction pour rechercher un Master par son ID dans un Stencil }
Function GetMasterByID(Const Stencil: TVisioStencil; MasterID: LongInt): Integer;
Var
 I: Integer;
Begin
 GetMasterByID := 0;
 For I := 1 to Stencil.MasterCount do Begin
  If Stencil.Masters[I].ID = MasterID Then Begin
   GetMasterByID := I;
   Exit;
  End;
 End;
End;

{ Fonction pour dÃ©tecter le format d'un fichier stencil }
Function DetectStencilFormat(Const FileName: String): Integer;
Var
 F: File;
 Buffer: Array[0..7] of Byte;
 BytesRead: Integer;
 Ext: String;
 I: Integer;
Begin
 DetectStencilFormat := VISIO_FORMAT_UNKNOWN;

 { VÃ©rifier l'extension d'abord }
 Ext := '';
 For I := Length(FileName) downto 1 do Begin
  If FileName[I] = '.' Then Begin
   Ext := Copy(FileName, I, Length(FileName) - I + 1);
   Break;
  End;
 End;

 { Convertir en minuscules }
 For I := 1 to Length(Ext) do Begin
  If (Ext[I] >= 'A') and (Ext[I] <= 'Z') Then
   Ext[I] := Chr(Ord(Ext[I]) + 32);
 End;

 Assign(F, FileName);
 {$I-}
 Reset(F, 1);
 {$I+}
 If IOResult <> 0 Then Exit;

 BlockRead(F, Buffer, 8, BytesRead);
 Close(F);

 If BytesRead < 4 Then Exit;

 { VÃ©rifier si c'est un fichier VSSX (ZIP) }
 If (Buffer[0] = $50) and (Buffer[1] = $4B) Then Begin
  DetectStencilFormat := VISIO_STENCIL_FORMAT_VSSX;
  Exit;
 End;

 { VÃ©rifier si c'est un fichier VSS (OLE Compound Document) }
 If BytesRead >= 8 Then Begin
  If (Buffer[0] = $D0) and (Buffer[1] = $CF) and
     (Buffer[2] = $11) and (Buffer[3] = $E0) and
     (Buffer[4] = $A1) and (Buffer[5] = $B6) and
     (Buffer[6] = $1A) and (Buffer[7] = $E1) Then Begin
   DetectStencilFormat := VISIO_STENCIL_FORMAT_VSS;
  End;
 End;
End;

{ Fonction pour charger un fichier stencil VSS (OLE binaire) }
Function LoadVSSFile(Const FileName: String; Var Stencil: TVisioStencil): Boolean;
Var
 F: File;
 Header: TOLEHeader;
 BytesRead: Integer;
 SectorSize: Integer;
Begin
 LoadVSSFile := False;
 InitStencil(Stencil);

 Assign(F, FileName);
 {$I-}
 Reset(F, 1);
 {$I+}
 If IOResult <> 0 Then Exit;

 { Lire l'en-tÃªte OLE }
 BlockRead(F, Header, SizeOf(TOLEHeader), BytesRead);
 If BytesRead < SizeOf(TOLEHeader) Then Begin
  Close(F);
  Exit;
 End;

 { VÃ©rifier la signature OLE }
 If (Header.Signature[0] <> $D0) or (Header.Signature[1] <> $CF) Then Begin
  Close(F);
  Exit;
 End;

 SectorSize := 1 shl Header.SectorShift;

 { Pour une implÃ©mentation complÃ¨te, il faudrait : }
 { 1. Parcourir le rÃ©pertoire OLE }
 { 2. Trouver les streams "Masters" }
 { 3. Parser chaque master }

 { Pour cette implÃ©mentation simplifiÃ©e, crÃ©er des masters de base }
 Stencil.Name := 'Basic Shapes';
 Stencil.FilePath := FileName;
 Stencil.FileFormat := VISIO_STENCIL_FORMAT_VSS;

 Close(F);
 LoadVSSFile := True;
End;

{ Fonction pour charger un fichier stencil VSSX (ZIP/XML) }
Function LoadVSSXFile(Const FileName: String; Var Stencil: TVisioStencil): Boolean;
Var
 F: File;
 Buffer: Array[0..3] of Byte;
 BytesRead: Integer;
Begin
 LoadVSSXFile := False;
 InitStencil(Stencil);

 Assign(F, FileName);
 {$I-}
 Reset(F, 1);
 {$I+}
 If IOResult <> 0 Then Exit;

 { VÃ©rifier la signature ZIP }
 BlockRead(F, Buffer, 4, BytesRead);
 If BytesRead < 4 Then Begin
  Close(F);
  Exit;
 End;

 If (Buffer[0] <> $50) or (Buffer[1] <> $4B) Then Begin
  Close(F);
  Exit;
 End;

 { Pour une implÃ©mentation complÃ¨te, il faudrait : }
 { 1. DÃ©compresser le ZIP }
 { 2. Lire visio/masters/masters.xml }
 { 3. Parser chaque master XML }

 Stencil.Name := 'Basic Shapes';
 Stencil.FilePath := FileName;
 Stencil.FileFormat := VISIO_STENCIL_FORMAT_VSSX;

 Close(F);
 LoadVSSXFile := True;
End;

{ Fonction principale pour charger un fichier stencil }
Function LoadStencilFile(Const FileName: String): Integer;
Var
 FileFormat: Integer;
 NewStencil: TVisioStencil;
 Success: Boolean;
Begin
 LoadStencilFile := 0;

 If StencilCount >= MAX_STENCILS Then Exit;

 FileFormat := DetectStencilFormat(FileName);
 Success := False;

 Case FileFormat of
  VISIO_STENCIL_FORMAT_VSS: Begin
   Success := LoadVSSFile(FileName, NewStencil);
  End;
  VISIO_STENCIL_FORMAT_VSSX: Begin
   Success := LoadVSSXFile(FileName, NewStencil);
  End;
 End;

 If Success Then Begin
  Inc(StencilCount);
  Stencils[StencilCount] := NewStencil;
  LoadStencilFile := StencilCount;
 End;
End;

{ Fonction pour sauvegarder un stencil au format VSSX (ZIP/XML) }
Function SaveVSSXFile(Const FileName: String; Const Stencil: TVisioStencil): Boolean;
Var
 F: File;
 LocalHeader: Array[0..29] of Byte;
 CentralDir: Array[0..45] of Byte;
 EndRecord: Array[0..21] of Byte;
 XMLData: String;
 BytesWritten: Integer;
 I: Integer;
 FileOffset, CentralDirOffset: LongInt;
 XMLSize: Integer;
 CRC: LongInt;
 TempStr: String;
Begin
 SaveVSSXFile := False;

 Assign(F, FileName);
 {$I-}
 Rewrite(F, 1);
 {$I+}
 If IOResult <> 0 Then Exit;

 FileOffset := 0;

 { Construire le contenu XML du stencil }
 XMLData := '<?xml version="1.0" encoding="UTF-8"?>' + #13#10;
 XMLData := XMLData + '<VisioStencil xmlns="http://schemas.microsoft.com/visio/2003/core">' + #13#10;
 XMLData := XMLData + '  <Masters>' + #13#10;

 For I := 1 to Stencil.MasterCount do Begin
  XMLData := XMLData + '    <Master ID="' + Chr(48 + I) + '" Name="' + Stencil.Masters[I].Name + '">' + #13#10;
  XMLData := XMLData + '      <UniqueID>' + Stencil.Masters[I].UniqueID + '</UniqueID>' + #13#10;
  XMLData := XMLData + '      <PageSheet>' + #13#10;

  Str(Stencil.Masters[I].Width:0:2, TempStr);
  XMLData := XMLData + '        <PageWidth>' + TempStr + '</PageWidth>' + #13#10;
  Str(Stencil.Masters[I].Height:0:2, TempStr);
  XMLData := XMLData + '        <PageHeight>' + TempStr + '</PageHeight>' + #13#10;

  XMLData := XMLData + '      </PageSheet>' + #13#10;
  XMLData := XMLData + '      <Shapes>' + #13#10;
  XMLData := XMLData + '        <Shape>' + #13#10;

  Case Stencil.Masters[I].BaseShape.ShapeType of
   VISIO_SHAPE_RECTANGLE: TempStr := 'Rectangle';
   VISIO_SHAPE_ELLIPSE: TempStr := 'Ellipse';
   VISIO_SHAPE_LINE: TempStr := 'Line';
   VISIO_SHAPE_CONNECTOR: TempStr := 'Connector';
   VISIO_SHAPE_TEXT: TempStr := 'Text';
  Else
   TempStr := 'Shape';
  End;
  XMLData := XMLData + '          <Name>' + TempStr + '</Name>' + #13#10;

  XMLData := XMLData + '          <XForm>' + #13#10;
  Str(Stencil.Masters[I].BaseShape.Width:0:2, TempStr);
  XMLData := XMLData + '            <Width>' + TempStr + '</Width>' + #13#10;
  Str(Stencil.Masters[I].BaseShape.Height:0:2, TempStr);
  XMLData := XMLData + '            <Height>' + TempStr + '</Height>' + #13#10;
  XMLData := XMLData + '          </XForm>' + #13#10;

  XMLData := XMLData + '        </Shape>' + #13#10;
  XMLData := XMLData + '      </Shapes>' + #13#10;
  XMLData := XMLData + '    </Master>' + #13#10;
 End;

 XMLData := XMLData + '  </Masters>' + #13#10;
 XMLData := XMLData + '</VisioStencil>' + #13#10;

 XMLSize := Length(XMLData);
 CRC := CalcCRC32(XMLData[1], XMLSize);

 { Ã‰crire l'en-tÃªte local du fichier ZIP }
 LocalHeader[0] := $50;  { P }
 LocalHeader[1] := $4B;  { K }
 LocalHeader[2] := $03;
 LocalHeader[3] := $04;
 LocalHeader[4] := 20;   { Version }
 LocalHeader[5] := 0;
 LocalHeader[6] := 0;
 LocalHeader[7] := 0;
 LocalHeader[8] := 0;
 LocalHeader[9] := 0;
 LocalHeader[10] := 0;
 LocalHeader[11] := 0;
 LocalHeader[12] := 0;
 LocalHeader[13] := 0;
 LocalHeader[14] := CRC and $FF;
 LocalHeader[15] := (CRC shr 8) and $FF;
 LocalHeader[16] := (CRC shr 16) and $FF;
 LocalHeader[17] := (CRC shr 24) and $FF;
 LocalHeader[18] := XMLSize and $FF;
 LocalHeader[19] := (XMLSize shr 8) and $FF;
 LocalHeader[20] := (XMLSize shr 16) and $FF;
 LocalHeader[21] := (XMLSize shr 24) and $FF;
 LocalHeader[22] := XMLSize and $FF;
 LocalHeader[23] := (XMLSize shr 8) and $FF;
 LocalHeader[24] := (XMLSize shr 16) and $FF;
 LocalHeader[25] := (XMLSize shr 24) and $FF;
 LocalHeader[26] := 19;  { Longueur du nom }
 LocalHeader[27] := 0;
 LocalHeader[28] := 0;
 LocalHeader[29] := 0;

 BlockWrite(F, LocalHeader, 30, BytesWritten);
 FileOffset := FileOffset + 30;

 { Nom du fichier }
 TempStr := 'visio/masters.xml';
 BlockWrite(F, TempStr[1], 17, BytesWritten);
 FileOffset := FileOffset + 17;

 { DonnÃ©es XML }
 BlockWrite(F, XMLData[1], XMLSize, BytesWritten);
 FileOffset := FileOffset + XMLSize;

 CentralDirOffset := FileOffset;

 { Ã‰crire l'entrÃ©e du rÃ©pertoire central }
 CentralDir[0] := $50;
 CentralDir[1] := $4B;
 CentralDir[2] := $01;
 CentralDir[3] := $02;
 CentralDir[4] := 20;
 CentralDir[5] := 0;
 CentralDir[6] := 20;
 CentralDir[7] := 0;
 CentralDir[8] := 0;
 CentralDir[9] := 0;
 CentralDir[10] := 0;
 CentralDir[11] := 0;
 CentralDir[12] := 0;
 CentralDir[13] := 0;
 CentralDir[14] := 0;
 CentralDir[15] := 0;
 CentralDir[16] := CRC and $FF;
 CentralDir[17] := (CRC shr 8) and $FF;
 CentralDir[18] := (CRC shr 16) and $FF;
 CentralDir[19] := (CRC shr 24) and $FF;
 CentralDir[20] := XMLSize and $FF;
 CentralDir[21] := (XMLSize shr 8) and $FF;
 CentralDir[22] := (XMLSize shr 16) and $FF;
 CentralDir[23] := (XMLSize shr 24) and $FF;
 CentralDir[24] := XMLSize and $FF;
 CentralDir[25] := (XMLSize shr 8) and $FF;
 CentralDir[26] := (XMLSize shr 16) and $FF;
 CentralDir[27] := (XMLSize shr 24) and $FF;
 CentralDir[28] := 17;
 CentralDir[29] := 0;
 CentralDir[30] := 0;
 CentralDir[31] := 0;
 CentralDir[32] := 0;
 CentralDir[33] := 0;
 CentralDir[34] := 0;
 CentralDir[35] := 0;
 CentralDir[36] := 0;
 CentralDir[37] := 0;
 CentralDir[38] := 0;
 CentralDir[39] := 0;
 CentralDir[40] := 0;
 CentralDir[41] := 0;
 CentralDir[42] := 0;
 CentralDir[43] := 0;
 CentralDir[44] := 0;
 CentralDir[45] := 0;

 BlockWrite(F, CentralDir, 46, BytesWritten);
 FileOffset := FileOffset + 46;

 { Nom du fichier }
 TempStr := 'visio/masters.xml';
 BlockWrite(F, TempStr[1], 17, BytesWritten);
 FileOffset := FileOffset + 17;

 { Enregistrement de fin }
 EndRecord[0] := $50;
 EndRecord[1] := $4B;
 EndRecord[2] := $05;
 EndRecord[3] := $06;
 EndRecord[4] := 0;
 EndRecord[5] := 0;
 EndRecord[6] := 0;
 EndRecord[7] := 0;
 EndRecord[8] := 1;
 EndRecord[9] := 0;
 EndRecord[10] := 1;
 EndRecord[11] := 0;
 EndRecord[12] := 63;  { Taille du rÃ©pertoire central }
 EndRecord[13] := 0;
 EndRecord[14] := 0;
 EndRecord[15] := 0;
 EndRecord[16] := CentralDirOffset and $FF;
 EndRecord[17] := (CentralDirOffset shr 8) and $FF;
 EndRecord[18] := (CentralDirOffset shr 16) and $FF;
 EndRecord[19] := (CentralDirOffset shr 24) and $FF;
 EndRecord[20] := 0;
 EndRecord[21] := 0;

 BlockWrite(F, EndRecord, 22, BytesWritten);

 Close(F);
 SaveVSSXFile := True;
End;

{ Fonction principale pour sauvegarder un stencil }
Function SaveStencilFile(StencilIndex: Integer; Const FileName: String): Boolean;
Var
 OK: Boolean;
Begin
 OK := False;
 SaveStencilFile := False;

 If (StencilIndex < 1) or (StencilIndex > StencilCount) Then Exit;

 { Toujours sauvegarder au format VSSX (moderne) }
 OK := SaveVSSXFile(FileName, Stencils[StencilIndex]);

 If OK Then Begin
  Stencils[StencilIndex].FilePath := FileName;
  Stencils[StencilIndex].IsModified := False;
 End;
 SaveStencilFile := OK;
End;

{ ProcÃ©dure pour crÃ©er un nouveau stencil }
Function CreateNewStencil(Const StencilName: String): Integer;
Begin
 CreateNewStencil := 0;

 If StencilCount >= MAX_STENCILS Then Exit;

 Inc(StencilCount);
 InitStencil(Stencils[StencilCount]);
 Stencils[StencilCount].Name := StencilName;
 Stencils[StencilCount].IsModified := True;

 CreateNewStencil := StencilCount;
End;

{ ProcÃ©dure pour crÃ©er des masters de formes de base }
Procedure CreateBasicShapeMasters(StencilIndex: Integer);
Var
 Master: TVisioMaster;
Begin
 If (StencilIndex < 1) or (StencilIndex > StencilCount) Then Exit;

 { Master Rectangle }
 InitMaster(Master);
 Master.Name := 'Rectangle';
 Master.UniqueID := GenerateSimpleGUID;
 Master.BaseShape.ShapeType := VISIO_SHAPE_RECTANGLE;
 Master.BaseShape.Width := 100;
 Master.BaseShape.Height := 60;
 Master.BaseShape.FillColor := $FFFFFF;
 Master.BaseShape.LineColor := $000000;
 Master.Width := 100;
 Master.Height := 60;
 Master.OffsetX := 50;
 Master.OffsetY := 30;
 Master.ConnectionPointCount := 4;
 Master.ConnectionPoints[1].X := 50; Master.ConnectionPoints[1].Y := 0;
 Master.ConnectionPoints[2].X := 100; Master.ConnectionPoints[2].Y := 30;
 Master.ConnectionPoints[3].X := 50; Master.ConnectionPoints[3].Y := 60;
 Master.ConnectionPoints[4].X := 0; Master.ConnectionPoints[4].Y := 30;
 AddMasterToStencil(Stencils[StencilIndex], Master);

 { Master Ellipse }
 InitMaster(Master);
 Master.Name := 'Ellipse';
 Master.UniqueID := GenerateSimpleGUID;
 Master.BaseShape.ShapeType := VISIO_SHAPE_ELLIPSE;
 Master.BaseShape.Width := 80;
 Master.BaseShape.Height := 80;
 Master.BaseShape.FillColor := $FFFFFF;
 Master.BaseShape.LineColor := $000000;
 Master.Width := 80;
 Master.Height := 80;
 Master.OffsetX := 40;
 Master.OffsetY := 40;
 Master.ConnectionPointCount := 4;
 Master.ConnectionPoints[1].X := 40; Master.ConnectionPoints[1].Y := 0;
 Master.ConnectionPoints[2].X := 80; Master.ConnectionPoints[2].Y := 40;
 Master.ConnectionPoints[3].X := 40; Master.ConnectionPoints[3].Y := 80;
 Master.ConnectionPoints[4].X := 0; Master.ConnectionPoints[4].Y := 40;
 AddMasterToStencil(Stencils[StencilIndex], Master);

 { Master Losange (Diamond) }
 InitMaster(Master);
 Master.Name := 'Diamond';
 Master.UniqueID := GenerateSimpleGUID;
 Master.BaseShape.ShapeType := VISIO_SHAPE_RECTANGLE;
 Master.BaseShape.Width := 80;
 Master.BaseShape.Height := 80;
 Master.BaseShape.FillColor := $FFFFFF;
 Master.BaseShape.LineColor := $000000;
 Master.Width := 80;
 Master.Height := 80;
 Master.OffsetX := 40;
 Master.OffsetY := 40;
 Master.ConnectionPointCount := 4;
 Master.ConnectionPoints[1].X := 40; Master.ConnectionPoints[1].Y := 0;
 Master.ConnectionPoints[2].X := 80; Master.ConnectionPoints[2].Y := 40;
 Master.ConnectionPoints[3].X := 40; Master.ConnectionPoints[3].Y := 80;
 Master.ConnectionPoints[4].X := 0; Master.ConnectionPoints[4].Y := 40;
 AddMasterToStencil(Stencils[StencilIndex], Master);

 { Master Ligne }
 InitMaster(Master);
 Master.Name := 'Line';
 Master.UniqueID := GenerateSimpleGUID;
 Master.BaseShape.ShapeType := VISIO_SHAPE_LINE;
 Master.BaseShape.Width := 100;
 Master.BaseShape.Height := 0;
 Master.BaseShape.FillColor := $000000;
 Master.BaseShape.LineColor := $000000;
 Master.Width := 100;
 Master.Height := 2;
 Master.OffsetX := 50;
 Master.OffsetY := 1;
 Master.ConnectionPointCount := 2;
 Master.ConnectionPoints[1].X := 0; Master.ConnectionPoints[1].Y := 1;
 Master.ConnectionPoints[2].X := 100; Master.ConnectionPoints[2].Y := 1;
 AddMasterToStencil(Stencils[StencilIndex], Master);

 { Master Connecteur }
 InitMaster(Master);
 Master.Name := 'Connector';
 Master.UniqueID := GenerateSimpleGUID;
 Master.BaseShape.ShapeType := VISIO_SHAPE_CONNECTOR;
 Master.BaseShape.Width := 100;
 Master.BaseShape.Height := 0;
 Master.BaseShape.FillColor := $000000;
 Master.BaseShape.LineColor := $000000;
 Master.Width := 100;
 Master.Height := 2;
 Master.OffsetX := 50;
 Master.OffsetY := 1;
 Master.ConnectionPointCount := 2;
 Master.ConnectionPoints[1].X := 0; Master.ConnectionPoints[1].Y := 1;
 Master.ConnectionPoints[2].X := 100; Master.ConnectionPoints[2].Y := 1;
 AddMasterToStencil(Stencils[StencilIndex], Master);

 { Master Texte }
 InitMaster(Master);
 Master.Name := 'Text';
 Master.UniqueID := GenerateSimpleGUID;
 Master.BaseShape.ShapeType := VISIO_SHAPE_TEXT;
 Master.BaseShape.Width := 120;
 Master.BaseShape.Height := 30;
 Master.BaseShape.FillColor := $FFFFFF;
 Master.BaseShape.LineColor := $000000;
 Master.BaseShape.Text := 'Text';
 Master.Width := 120;
 Master.Height := 30;
 Master.OffsetX := 60;
 Master.OffsetY := 15;
 Master.ConnectionPointCount := 4;
 Master.ConnectionPoints[1].X := 60; Master.ConnectionPoints[1].Y := 0;
 Master.ConnectionPoints[2].X := 120; Master.ConnectionPoints[2].Y := 15;
 Master.ConnectionPoints[3].X := 60; Master.ConnectionPoints[3].Y := 30;
 Master.ConnectionPoints[4].X := 0; Master.ConnectionPoints[4].Y := 15;
 AddMasterToStencil(Stencils[StencilIndex], Master);
End;

{ ProcÃ©dure pour fermer un stencil }
Procedure CloseStencil(StencilIndex: Integer);
Var
 I: Integer;
Begin
 If (StencilIndex < 1) or (StencilIndex > StencilCount) Then Exit;

 { DÃ©caler les stencils suivants }
 For I := StencilIndex to StencilCount - 1 do
  Stencils[I] := Stencils[I + 1];

 Dec(StencilCount);

 { Ajuster le stencil courant si nÃ©cessaire }
 If CurrentStencil > StencilCount Then
  CurrentStencil := StencilCount;
End;

{ ProcÃ©dure pour initialiser le systÃ¨me de stencils }
Procedure InitStencilSystem;
Var
 I: Integer;
 NewStencilIdx: Integer;
Begin
 StencilCount := 0;
 CurrentStencil := 0;
 NextMasterID := 1;

 For I := 1 to MAX_STENCILS do
  InitStencil(Stencils[I]);

 { CrÃ©er un stencil par dÃ©faut avec les formes de base }
 NewStencilIdx := CreateNewStencil('Basic Shapes');
 If NewStencilIdx > 0 Then Begin
  CreateBasicShapeMasters(NewStencilIdx);
  CurrentStencil := NewStencilIdx;
 End;
End;

{ ============================================================================ }
{ === FIN DES FONCTIONS DE GESTION DES STENCILS ET MASTERS === }
{ ============================================================================ }

{ ============================================================================ }
{ === FONCTIONS D'IMPORT SVG === }
{ ============================================================================ }

{ Constantes pour le parsing SVG }
Const
 SVG_MAX_ATTR_LENGTH = 255;      { Longueur max d'un attribut }
 SVG_MAX_PATH_POINTS = 100;      { Nombre max de points dans un path }
 SVG_SCALE_FACTOR = 1.0;         { Facteur d'Ã©chelle pour la conversion }

Type
 { Structure pour un attribut SVG }
 TSVGAttribute = Record
  Name: String[50];
  Value: String[SVG_MAX_ATTR_LENGTH];
 End;

 { Structure pour les donnÃ©es de parsing }
 TSVGParseState = Record
  CurrentX, CurrentY: Real;      { Position courante pour les paths }
  StartX, StartY: Real;          { Point de dÃ©part du sous-chemin }
  FillColor: LongInt;            { Couleur de remplissage }
  StrokeColor: LongInt;          { Couleur de trait }
  StrokeWidth: Real;             { Ã‰paisseur du trait }
  TransformX, TransformY: Real;  { Translation }
  ScaleX, ScaleY: Real;          { Ã‰chelle }
 End;

Var
 SVGParseState: TSVGParseState;

{ Fonction pour sauter les espaces dans une chaÃ®ne }
Function SVGSkipWhitespace(Const S: String; StartPos: Integer): Integer;
Begin
 While (StartPos <= Length(S)) and
       ((S[StartPos] = ' ') or (S[StartPos] = #9) or
        (S[StartPos] = #10) or (S[StartPos] = #13) or
        (S[StartPos] = ',')) do
  Inc(StartPos);
 SVGSkipWhitespace := StartPos;
End;

{ Fonction pour parser un nombre rÃ©el dans une chaÃ®ne }
Function SVGParseNumber(Const S: String; Var Pos: Integer): Real;
Var
 NumStr: String;
 Value: Real;
 Code: Integer;
 Negative: Boolean;
Begin
 SVGParseNumber := 0;
 Pos := SVGSkipWhitespace(S, Pos);
 If Pos > Length(S) Then Exit;

 NumStr := '';
 Negative := False;

 { GÃ©rer le signe }
 If S[Pos] = '-' Then Begin
  Negative := True;
  Inc(Pos);
 End
 Else If S[Pos] = '+' Then
  Inc(Pos);

 { Parser les chiffres et le point dÃ©cimal }
 While (Pos <= Length(S)) and
       (((S[Pos] >= '0') and (S[Pos] <= '9')) or (S[Pos] = '.')) do Begin
  NumStr := NumStr + S[Pos];
  Inc(Pos);
 End;

 { GÃ©rer l'exposant (notation scientifique) }
 If (Pos <= Length(S)) and ((S[Pos] = 'e') or (S[Pos] = 'E')) Then Begin
  NumStr := NumStr + S[Pos];
  Inc(Pos);
  If (Pos <= Length(S)) and ((S[Pos] = '+') or (S[Pos] = '-')) Then Begin
   NumStr := NumStr + S[Pos];
   Inc(Pos);
  End;
  While (Pos <= Length(S)) and (S[Pos] >= '0') and (S[Pos] <= '9') do Begin
   NumStr := NumStr + S[Pos];
   Inc(Pos);
  End;
 End;

 If NumStr <> '' Then Begin
  Val(NumStr, Value, Code);
  If Code = 0 Then Begin
   If Negative Then Value := -Value;
   SVGParseNumber := Value;
  End;
 End;
End;

{ Fonction pour convertir une valeur hexadÃ©cimale en entier }
Function HexToInt(Const HexStr: String): LongInt;
Var
 I: Integer;
 C: Char;
 Value: LongInt;
Begin
 Value := 0;
 For I := 1 to Length(HexStr) do Begin
  C := HexStr[I];
  Value := Value * 16;
  If (C >= '0') and (C <= '9') Then
   Value := Value + (Ord(C) - Ord('0'))
  Else If (C >= 'a') and (C <= 'f') Then
   Value := Value + (Ord(C) - Ord('a') + 10)
  Else If (C >= 'A') and (C <= 'F') Then
   Value := Value + (Ord(C) - Ord('A') + 10);
 End;
 HexToInt := Value;
End;

{ Fonction pour parser une couleur SVG et retourner une couleur Pascal }
Function SVGParseColor(Const ColorStr: String): Integer;
Var
 S: String;
 R, G, B: Integer;
 I: Integer;
Begin
 SVGParseColor := 0;  { Noir par dÃ©faut }
 S := ColorStr;

 { Supprimer les espaces }
 While (Length(S) > 0) and (S[1] = ' ') do Delete(S, 1, 1);
 While (Length(S) > 0) and (S[Length(S)] = ' ') do Delete(S, Length(S), 1);

 { Convertir en minuscules }
 For I := 1 to Length(S) do
  If (S[I] >= 'A') and (S[I] <= 'Z') Then
   S[I] := Chr(Ord(S[I]) + 32);

 { Couleur hexadÃ©cimale #RRGGBB ou #RGB }
 If (Length(S) > 0) and (S[1] = '#') Then Begin
  Delete(S, 1, 1);
  If Length(S) = 6 Then Begin
   R := HexToInt(Copy(S, 1, 2));
   G := HexToInt(Copy(S, 3, 2));
   B := HexToInt(Copy(S, 5, 2));
  End
  Else If Length(S) = 3 Then Begin
   R := HexToInt(S[1] + S[1]);
   G := HexToInt(S[2] + S[2]);
   B := HexToInt(S[3] + S[3]);
  End
  Else Begin
   R := 0; G := 0; B := 0;
  End;

  { Convertir RGB en couleur Pascal (palette 16 couleurs) }
  { Approximation vers la couleur la plus proche }
  If (R < 64) and (G < 64) and (B < 64) Then SVGParseColor := 0   { Noir }
  Else If (R > 192) and (G > 192) and (B > 192) Then SVGParseColor := 15 { Blanc }
  Else If (R > 192) and (G < 64) and (B < 64) Then SVGParseColor := 4  { Rouge }
  Else If (R < 64) and (G > 192) and (B < 64) Then SVGParseColor := 2  { Vert }
  Else If (R < 64) and (G < 64) and (B > 192) Then SVGParseColor := 1  { Bleu }
  Else If (R > 192) and (G > 192) and (B < 64) Then SVGParseColor := 14 { Jaune }
  Else If (R > 192) and (G < 64) and (B > 192) Then SVGParseColor := 5  { Magenta }
  Else If (R < 64) and (G > 192) and (B > 192) Then SVGParseColor := 3  { Cyan }
  Else If (R > 128) and (G > 128) and (B > 128) Then SVGParseColor := 7 { Gris clair }
  Else SVGParseColor := 8;  { Gris foncÃ© }
  Exit;
 End;

 { Couleurs nommÃ©es }
 If S = 'black' Then SVGParseColor := 0
 Else If S = 'blue' Then SVGParseColor := 1
 Else If S = 'green' Then SVGParseColor := 2
 Else If S = 'cyan' Then SVGParseColor := 3
 Else If S = 'red' Then SVGParseColor := 4
 Else If S = 'magenta' Then SVGParseColor := 5
 Else If S = 'brown' Then SVGParseColor := 6
 Else If (S = 'lightgray') or (S = 'lightgrey') or (S = 'silver') Then SVGParseColor := 7
 Else If (S = 'darkgray') or (S = 'darkgrey') or (S = 'gray') or (S = 'grey') Then SVGParseColor := 8
 Else If S = 'lightblue' Then SVGParseColor := 9
 Else If (S = 'lightgreen') or (S = 'lime') Then SVGParseColor := 10
 Else If S = 'lightcyan' Then SVGParseColor := 11
 Else If (S = 'lightred') or (S = 'salmon') Then SVGParseColor := 12
 Else If (S = 'lightmagenta') or (S = 'pink') Then SVGParseColor := 13
 Else If S = 'yellow' Then SVGParseColor := 14
 Else If S = 'white' Then SVGParseColor := 15
 Else If S = 'orange' Then SVGParseColor := 6
 Else If S = 'none' Then SVGParseColor := -1;  { Pas de couleur }
End;

{ Fonction pour extraire la valeur d'un attribut dans une balise XML }
Function SVGGetAttribute(Const Tag, AttrName: String): String;
Var
 Pos, EndPos: Integer;
 AttrSearch: String;
 QuoteChar: Char;
Begin
 SVGGetAttribute := '';
 AttrSearch := AttrName + '="';
 Pos := 1;

 { Chercher l'attribut avec guillemets doubles }
 While Pos <= Length(Tag) - Length(AttrSearch) do Begin
  If Copy(Tag, Pos, Length(AttrSearch)) = AttrSearch Then Begin
   Pos := Pos + Length(AttrSearch);
   EndPos := Pos;
   While (EndPos <= Length(Tag)) and (Tag[EndPos] <> '"') do
    Inc(EndPos);
   SVGGetAttribute := Copy(Tag, Pos, EndPos - Pos);
   Exit;
  End;
  Inc(Pos);
 End;

 { Essayer avec guillemets simples }
 AttrSearch := AttrName + '=''';
 Pos := 1;
 While Pos <= Length(Tag) - Length(AttrSearch) do Begin
  If Copy(Tag, Pos, Length(AttrSearch)) = AttrSearch Then Begin
   Pos := Pos + Length(AttrSearch);
   EndPos := Pos;
   While (EndPos <= Length(Tag)) and (Tag[EndPos] <> '''') do
    Inc(EndPos);
   SVGGetAttribute := Copy(Tag, Pos, EndPos - Pos);
   Exit;
  End;
  Inc(Pos);
 End;
End;

{ Fonction pour initialiser l'Ã©tat de parsing SVG }
Procedure InitSVGParseState;
Begin
 SVGParseState.CurrentX := 0;
 SVGParseState.CurrentY := 0;
 SVGParseState.StartX := 0;
 SVGParseState.StartY := 0;
 SVGParseState.FillColor := $FFFFFF;
 SVGParseState.StrokeColor := $000000;
 SVGParseState.StrokeWidth := 1;
 SVGParseState.TransformX := 0;
 SVGParseState.TransformY := 0;
 SVGParseState.ScaleX := 1;
 SVGParseState.ScaleY := 1;
End;

{ Fonction pour parser un Ã©lÃ©ment SVG rect }
Function ParseSVGRect(Const Tag: String; Var Shape: TShapeObject): Boolean;
Var
 X, Y, W, H, RX, RY: Real;
 TempStr: String;
 Pos: Integer;
Begin
 ParseSVGRect := False;

 { Parser les attributs }
 TempStr := SVGGetAttribute(Tag, 'x');
 If TempStr = '' Then X := 0 Else Begin Pos := 1; X := SVGParseNumber(TempStr, Pos); End;

 TempStr := SVGGetAttribute(Tag, 'y');
 If TempStr = '' Then Y := 0 Else Begin Pos := 1; Y := SVGParseNumber(TempStr, Pos); End;

 TempStr := SVGGetAttribute(Tag, 'width');
 If TempStr = '' Then Exit;
 Pos := 1;
 W := SVGParseNumber(TempStr, Pos);

 TempStr := SVGGetAttribute(Tag, 'height');
 If TempStr = '' Then Exit;
 Pos := 1;
 H := SVGParseNumber(TempStr, Pos);

 { CrÃ©er la forme }
 Shape.ShapeType := stRectangle;
 Shape.X1 := Round(X * SVG_SCALE_FACTOR);
 Shape.Y1 := Round(Y * SVG_SCALE_FACTOR);
 Shape.X2 := Round((X + W) * SVG_SCALE_FACTOR);
 Shape.Y2 := Round((Y + H) * SVG_SCALE_FACTOR);

 { Parser les couleurs }
 TempStr := SVGGetAttribute(Tag, 'fill');
 If TempStr <> '' Then Shape.FillColor := SVGParseColor(TempStr)
 Else Shape.FillColor := 15;  { Blanc par dÃ©faut }

 TempStr := SVGGetAttribute(Tag, 'stroke');
 If TempStr <> '' Then Shape.LineColor := SVGParseColor(TempStr)
 Else Shape.LineColor := 0;  { Noir par dÃ©faut }

 TempStr := SVGGetAttribute(Tag, 'stroke-width');
 If TempStr <> '' Then Begin
  Pos := 1;
  Shape.LineWidth := Round(SVGParseNumber(TempStr, Pos));
 End
 Else Shape.LineWidth := 1;

 Shape.LineStyle := 0;
 Shape.Selected := False;
 Shape.LayerIndex := 1;
 Shape.GroupID := 0;
 Shape.PointCount := 0;

 ParseSVGRect := True;
End;

{ Fonction pour parser un Ã©lÃ©ment SVG circle }
Function ParseSVGCircle(Const Tag: String; Var Shape: TShapeObject): Boolean;
Var
 CX, CY, R: Real;
 TempStr: String;
 Pos: Integer;
Begin
 ParseSVGCircle := False;

 { Parser les attributs }
 TempStr := SVGGetAttribute(Tag, 'cx');
 If TempStr = '' Then CX := 0 Else Begin Pos := 1; CX := SVGParseNumber(TempStr, Pos); End;

 TempStr := SVGGetAttribute(Tag, 'cy');
 If TempStr = '' Then CY := 0 Else Begin Pos := 1; CY := SVGParseNumber(TempStr, Pos); End;

 TempStr := SVGGetAttribute(Tag, 'r');
 If TempStr = '' Then Exit;
 Pos := 1;
 R := SVGParseNumber(TempStr, Pos);

 { CrÃ©er la forme (ellipse avec mÃªme rayon X et Y) }
 Shape.ShapeType := stEllipse;
 Shape.X1 := Round((CX - R) * SVG_SCALE_FACTOR);
 Shape.Y1 := Round((CY - R) * SVG_SCALE_FACTOR);
 Shape.X2 := Round((CX + R) * SVG_SCALE_FACTOR);
 Shape.Y2 := Round((CY + R) * SVG_SCALE_FACTOR);

 { Parser les couleurs }
 TempStr := SVGGetAttribute(Tag, 'fill');
 If TempStr <> '' Then Shape.FillColor := SVGParseColor(TempStr)
 Else Shape.FillColor := 15;

 TempStr := SVGGetAttribute(Tag, 'stroke');
 If TempStr <> '' Then Shape.LineColor := SVGParseColor(TempStr)
 Else Shape.LineColor := 0;

 TempStr := SVGGetAttribute(Tag, 'stroke-width');
 If TempStr <> '' Then Begin
  Pos := 1;
  Shape.LineWidth := Round(SVGParseNumber(TempStr, Pos));
 End
 Else Shape.LineWidth := 1;

 Shape.LineStyle := 0;
 Shape.Selected := False;
 Shape.LayerIndex := 1;
 Shape.GroupID := 0;
 Shape.PointCount := 0;

 ParseSVGCircle := True;
End;

{ Fonction pour parser un Ã©lÃ©ment SVG ellipse }
Function ParseSVGEllipse(Const Tag: String; Var Shape: TShapeObject): Boolean;
Var
 CX, CY, RX, RY: Real;
 TempStr: String;
 Pos: Integer;
Begin
 ParseSVGEllipse := False;

 { Parser les attributs }
 TempStr := SVGGetAttribute(Tag, 'cx');
 If TempStr = '' Then CX := 0 Else Begin Pos := 1; CX := SVGParseNumber(TempStr, Pos); End;

 TempStr := SVGGetAttribute(Tag, 'cy');
 If TempStr = '' Then CY := 0 Else Begin Pos := 1; CY := SVGParseNumber(TempStr, Pos); End;

 TempStr := SVGGetAttribute(Tag, 'rx');
 If TempStr = '' Then Exit;
 Pos := 1;
 RX := SVGParseNumber(TempStr, Pos);

 TempStr := SVGGetAttribute(Tag, 'ry');
 If TempStr = '' Then Exit;
 Pos := 1;
 RY := SVGParseNumber(TempStr, Pos);

 { CrÃ©er la forme }
 Shape.ShapeType := stEllipse;
 Shape.X1 := Round((CX - RX) * SVG_SCALE_FACTOR);
 Shape.Y1 := Round((CY - RY) * SVG_SCALE_FACTOR);
 Shape.X2 := Round((CX + RX) * SVG_SCALE_FACTOR);
 Shape.Y2 := Round((CY + RY) * SVG_SCALE_FACTOR);

 { Parser les couleurs }
 TempStr := SVGGetAttribute(Tag, 'fill');
 If TempStr <> '' Then Shape.FillColor := SVGParseColor(TempStr)
 Else Shape.FillColor := 15;

 TempStr := SVGGetAttribute(Tag, 'stroke');
 If TempStr <> '' Then Shape.LineColor := SVGParseColor(TempStr)
 Else Shape.LineColor := 0;

 TempStr := SVGGetAttribute(Tag, 'stroke-width');
 If TempStr <> '' Then Begin
  Pos := 1;
  Shape.LineWidth := Round(SVGParseNumber(TempStr, Pos));
 End
 Else Shape.LineWidth := 1;

 Shape.LineStyle := 0;
 Shape.Selected := False;
 Shape.LayerIndex := 1;
 Shape.GroupID := 0;
 Shape.PointCount := 0;

 ParseSVGEllipse := True;
End;

{ Fonction pour parser un Ã©lÃ©ment SVG line }
Function ParseSVGLine(Const Tag: String; Var Shape: TShapeObject): Boolean;
Var
 X1, Y1, X2, Y2: Real;
 TempStr: String;
 Pos: Integer;
Begin
 ParseSVGLine := False;

 { Parser les attributs }
 TempStr := SVGGetAttribute(Tag, 'x1');
 If TempStr = '' Then X1 := 0 Else Begin Pos := 1; X1 := SVGParseNumber(TempStr, Pos); End;

 TempStr := SVGGetAttribute(Tag, 'y1');
 If TempStr = '' Then Y1 := 0 Else Begin Pos := 1; Y1 := SVGParseNumber(TempStr, Pos); End;

 TempStr := SVGGetAttribute(Tag, 'x2');
 If TempStr = '' Then X2 := 0 Else Begin Pos := 1; X2 := SVGParseNumber(TempStr, Pos); End;

 TempStr := SVGGetAttribute(Tag, 'y2');
 If TempStr = '' Then Y2 := 0 Else Begin Pos := 1; Y2 := SVGParseNumber(TempStr, Pos); End;

 { CrÃ©er la forme }
 Shape.ShapeType := stLine;
 Shape.X1 := Round(X1 * SVG_SCALE_FACTOR);
 Shape.Y1 := Round(Y1 * SVG_SCALE_FACTOR);
 Shape.X2 := Round(X2 * SVG_SCALE_FACTOR);
 Shape.Y2 := Round(Y2 * SVG_SCALE_FACTOR);

 { Parser les couleurs (les lignes n'ont pas de remplissage) }
 Shape.FillColor := -1;  { Pas de remplissage }

 TempStr := SVGGetAttribute(Tag, 'stroke');
 If TempStr <> '' Then Shape.LineColor := SVGParseColor(TempStr)
 Else Shape.LineColor := 0;

 TempStr := SVGGetAttribute(Tag, 'stroke-width');
 If TempStr <> '' Then Begin
  Pos := 1;
  Shape.LineWidth := Round(SVGParseNumber(TempStr, Pos));
 End
 Else Shape.LineWidth := 1;

 Shape.LineStyle := 0;
 Shape.Selected := False;
 Shape.LayerIndex := 1;
 Shape.GroupID := 0;
 Shape.PointCount := 0;

 ParseSVGLine := True;
End;

{ Fonction pour parser un Ã©lÃ©ment SVG polygon ou polyline }
Function ParseSVGPolygon(Const Tag: String; Var Shape: TShapeObject; IsPolyline: Boolean): Boolean;
Var
 PointsStr, TempStr: String;
 Pos, I: Integer;
 X, Y: Real;
 MinX, MinY, MaxX, MaxY: Real;
Begin
 ParseSVGPolygon := False;

 PointsStr := SVGGetAttribute(Tag, 'points');
 If PointsStr = '' Then Exit;

 { Parser les points }
 Shape.PointCount := 0;
 Pos := 1;
 MinX := 32767; MinY := 32767;
 MaxX := -32767; MaxY := -32767;

 While (Pos <= Length(PointsStr)) and (Shape.PointCount < MAX_POLYGON_POINTS) do Begin
  Pos := SVGSkipWhitespace(PointsStr, Pos);
  If Pos > Length(PointsStr) Then Break;

  X := SVGParseNumber(PointsStr, Pos);
  Pos := SVGSkipWhitespace(PointsStr, Pos);
  Y := SVGParseNumber(PointsStr, Pos);

  Inc(Shape.PointCount);
  Shape.Points[Shape.PointCount].X := Round(X * SVG_SCALE_FACTOR);
  Shape.Points[Shape.PointCount].Y := Round(Y * SVG_SCALE_FACTOR);

  If X < MinX Then MinX := X;
  If Y < MinY Then MinY := Y;
  If X > MaxX Then MaxX := X;
  If Y > MaxY Then MaxY := Y;
 End;

 If Shape.PointCount < 2 Then Exit;

 { CrÃ©er la forme }
 Shape.ShapeType := stPolygon;
 Shape.X1 := Round(MinX * SVG_SCALE_FACTOR);
 Shape.Y1 := Round(MinY * SVG_SCALE_FACTOR);
 Shape.X2 := Round(MaxX * SVG_SCALE_FACTOR);
 Shape.Y2 := Round(MaxY * SVG_SCALE_FACTOR);

 { Parser les couleurs }
 TempStr := SVGGetAttribute(Tag, 'fill');
 If TempStr <> '' Then Shape.FillColor := SVGParseColor(TempStr)
 Else If IsPolyline Then Shape.FillColor := -1
 Else Shape.FillColor := 15;

 TempStr := SVGGetAttribute(Tag, 'stroke');
 If TempStr <> '' Then Shape.LineColor := SVGParseColor(TempStr)
 Else Shape.LineColor := 0;

 TempStr := SVGGetAttribute(Tag, 'stroke-width');
 If TempStr <> '' Then Begin
  Pos := 1;
  Shape.LineWidth := Round(SVGParseNumber(TempStr, Pos));
 End
 Else Shape.LineWidth := 1;

 Shape.LineStyle := 0;
 Shape.Selected := False;
 Shape.LayerIndex := 1;
 Shape.GroupID := 0;

 ParseSVGPolygon := True;
End;

{ Fonction pour parser un Ã©lÃ©ment SVG path (support basique M, L, H, V, Z, C, Q) }
Function ParseSVGPath(Const Tag: String; Var Shape: TShapeObject): Boolean;
Var
 PathData, TempStr: String;
 Pos, I: Integer;
 Cmd: Char;
 X, Y, X1, Y1, X2, Y2: Real;
 CurX, CurY, StartX, StartY: Real;
 MinX, MinY, MaxX, MaxY: Real;
 IsRelative: Boolean;
Begin
 ParseSVGPath := False;

 PathData := SVGGetAttribute(Tag, 'd');
 If PathData = '' Then Exit;

 { Parser le path }
 Shape.PointCount := 0;
 Pos := 1;
 CurX := 0; CurY := 0;
 StartX := 0; StartY := 0;
 MinX := 32767; MinY := 32767;
 MaxX := -32767; MaxY := -32767;

 While (Pos <= Length(PathData)) and (Shape.PointCount < MAX_POLYGON_POINTS) do Begin
  Pos := SVGSkipWhitespace(PathData, Pos);
  If Pos > Length(PathData) Then Break;

  Cmd := PathData[Pos];

  { VÃ©rifier si c'est une commande }
  If ((Cmd >= 'A') and (Cmd <= 'Z')) or ((Cmd >= 'a') and (Cmd <= 'z')) Then Begin
   Inc(Pos);
   IsRelative := (Cmd >= 'a') and (Cmd <= 'z');
   If IsRelative Then Cmd := Chr(Ord(Cmd) - 32);  { Convertir en majuscule }
  End;

  Pos := SVGSkipWhitespace(PathData, Pos);

  Case Cmd of
   'M': Begin { MoveTo }
    X := SVGParseNumber(PathData, Pos);
    Y := SVGParseNumber(PathData, Pos);
    If IsRelative Then Begin X := CurX + X; Y := CurY + Y; End;
    CurX := X; CurY := Y;
    StartX := X; StartY := Y;
    If Shape.PointCount < MAX_POLYGON_POINTS Then Begin
     Inc(Shape.PointCount);
     Shape.Points[Shape.PointCount].X := Round(X * SVG_SCALE_FACTOR);
     Shape.Points[Shape.PointCount].Y := Round(Y * SVG_SCALE_FACTOR);
    End;
    If X < MinX Then MinX := X;
    If Y < MinY Then MinY := Y;
    If X > MaxX Then MaxX := X;
    If Y > MaxY Then MaxY := Y;
   End;

   'L': Begin { LineTo }
    X := SVGParseNumber(PathData, Pos);
    Y := SVGParseNumber(PathData, Pos);
    If IsRelative Then Begin X := CurX + X; Y := CurY + Y; End;
    CurX := X; CurY := Y;
    If Shape.PointCount < MAX_POLYGON_POINTS Then Begin
     Inc(Shape.PointCount);
     Shape.Points[Shape.PointCount].X := Round(X * SVG_SCALE_FACTOR);
     Shape.Points[Shape.PointCount].Y := Round(Y * SVG_SCALE_FACTOR);
    End;
    If X < MinX Then MinX := X;
    If Y < MinY Then MinY := Y;
    If X > MaxX Then MaxX := X;
    If Y > MaxY Then MaxY := Y;
   End;

   'H': Begin { Horizontal LineTo }
    X := SVGParseNumber(PathData, Pos);
    If IsRelative Then X := CurX + X;
    CurX := X;
    If Shape.PointCount < MAX_POLYGON_POINTS Then Begin
     Inc(Shape.PointCount);
     Shape.Points[Shape.PointCount].X := Round(X * SVG_SCALE_FACTOR);
     Shape.Points[Shape.PointCount].Y := Round(CurY * SVG_SCALE_FACTOR);
    End;
    If X < MinX Then MinX := X;
    If X > MaxX Then MaxX := X;
   End;

   'V': Begin { Vertical LineTo }
    Y := SVGParseNumber(PathData, Pos);
    If IsRelative Then Y := CurY + Y;
    CurY := Y;
    If Shape.PointCount < MAX_POLYGON_POINTS Then Begin
     Inc(Shape.PointCount);
     Shape.Points[Shape.PointCount].X := Round(CurX * SVG_SCALE_FACTOR);
     Shape.Points[Shape.PointCount].Y := Round(Y * SVG_SCALE_FACTOR);
    End;
    If Y < MinY Then MinY := Y;
    If Y > MaxY Then MaxY := Y;
   End;

   'Z': Begin { ClosePath }
    CurX := StartX;
    CurY := StartY;
    { Fermer le chemin en revenant au point de dÃ©part }
   End;

   'C': Begin { Cubic Bezier - on simplifie en prenant le point final }
    X1 := SVGParseNumber(PathData, Pos);
    Y1 := SVGParseNumber(PathData, Pos);
    X2 := SVGParseNumber(PathData, Pos);
    Y2 := SVGParseNumber(PathData, Pos);
    X := SVGParseNumber(PathData, Pos);
    Y := SVGParseNumber(PathData, Pos);
    If IsRelative Then Begin X := CurX + X; Y := CurY + Y; End;
    CurX := X; CurY := Y;
    If Shape.PointCount < MAX_POLYGON_POINTS Then Begin
     Inc(Shape.PointCount);
     Shape.Points[Shape.PointCount].X := Round(X * SVG_SCALE_FACTOR);
     Shape.Points[Shape.PointCount].Y := Round(Y * SVG_SCALE_FACTOR);
    End;
    If X < MinX Then MinX := X;
    If Y < MinY Then MinY := Y;
    If X > MaxX Then MaxX := X;
    If Y > MaxY Then MaxY := Y;
   End;

   'Q': Begin { Quadratic Bezier - on simplifie en prenant le point final }
    X1 := SVGParseNumber(PathData, Pos);
    Y1 := SVGParseNumber(PathData, Pos);
    X := SVGParseNumber(PathData, Pos);
    Y := SVGParseNumber(PathData, Pos);
    If IsRelative Then Begin X := CurX + X; Y := CurY + Y; End;
    CurX := X; CurY := Y;
    If Shape.PointCount < MAX_POLYGON_POINTS Then Begin
     Inc(Shape.PointCount);
     Shape.Points[Shape.PointCount].X := Round(X * SVG_SCALE_FACTOR);
     Shape.Points[Shape.PointCount].Y := Round(Y * SVG_SCALE_FACTOR);
    End;
    If X < MinX Then MinX := X;
    If Y < MinY Then MinY := Y;
    If X > MaxX Then MaxX := X;
    If Y > MaxY Then MaxY := Y;
   End;

  Else
   { Commande inconnue, avancer }
   Inc(Pos);
  End;
 End;

 If Shape.PointCount < 2 Then Exit;

 { CrÃ©er la forme }
 Shape.ShapeType := stPolygon;
 Shape.X1 := Round(MinX * SVG_SCALE_FACTOR);
 Shape.Y1 := Round(MinY * SVG_SCALE_FACTOR);
 Shape.X2 := Round(MaxX * SVG_SCALE_FACTOR);
 Shape.Y2 := Round(MaxY * SVG_SCALE_FACTOR);

 { Parser les couleurs }
 TempStr := SVGGetAttribute(Tag, 'fill');
 If TempStr <> '' Then Shape.FillColor := SVGParseColor(TempStr)
 Else Shape.FillColor := 15;

 TempStr := SVGGetAttribute(Tag, 'stroke');
 If TempStr <> '' Then Shape.LineColor := SVGParseColor(TempStr)
 Else Shape.LineColor := 0;

 TempStr := SVGGetAttribute(Tag, 'stroke-width');
 If TempStr <> '' Then Begin
  Pos := 1;
  Shape.LineWidth := Round(SVGParseNumber(TempStr, Pos));
 End
 Else Shape.LineWidth := 1;

 Shape.LineStyle := 0;
 Shape.Selected := False;
 Shape.LayerIndex := 1;
 Shape.GroupID := 0;

 ParseSVGPath := True;
End;

{ Fonction pour parser un Ã©lÃ©ment SVG text }
Function ParseSVGText(Const Tag, TextContent: String; Var Shape: TShapeObject): Boolean;
Var
 X, Y: Real;
 TempStr: String;
 Pos: Integer;
Begin
 ParseSVGText := False;

 { Parser les attributs }
 TempStr := SVGGetAttribute(Tag, 'x');
 If TempStr = '' Then X := 0 Else Begin Pos := 1; X := SVGParseNumber(TempStr, Pos); End;

 TempStr := SVGGetAttribute(Tag, 'y');
 If TempStr = '' Then Y := 0 Else Begin Pos := 1; Y := SVGParseNumber(TempStr, Pos); End;

 { CrÃ©er la forme }
 Shape.ShapeType := stText;
 Shape.X1 := Round(X * SVG_SCALE_FACTOR);
 Shape.Y1 := Round(Y * SVG_SCALE_FACTOR) - 15;  { Ajuster pour la baseline }
 Shape.X2 := Shape.X1 + Length(TextContent) * 8;  { Estimation de la largeur }
 Shape.Y2 := Shape.Y1 + 20;  { Hauteur estimÃ©e }

 { Texte }
 If Length(TextContent) > 80 Then
  Shape.Text := Copy(TextContent, 1, 80)
 Else
  Shape.Text := TextContent;

 { Parser les couleurs }
 TempStr := SVGGetAttribute(Tag, 'fill');
 If TempStr <> '' Then Shape.FillColor := SVGParseColor(TempStr)
 Else Shape.FillColor := 0;  { Noir par dÃ©faut pour le texte }

 Shape.LineColor := Shape.FillColor;
 Shape.LineWidth := 1;
 Shape.LineStyle := 0;
 Shape.Selected := False;
 Shape.LayerIndex := 1;
 Shape.GroupID := 0;
 Shape.PointCount := 0;

 ParseSVGText := True;
End;

{ Fonction principale pour charger un fichier SVG }
Function LoadSVGFile(Const FileName: String): Boolean;
Var
 F: Text;
 Line, Tag, TagName, TextContent: String;
 TotalContent: String;
 I, TagStart, TagEnd, ContentStart: Integer;
 Shape: TShapeObject;
 InTag: Boolean;
 C: Char;
Begin
 LoadSVGFile := False;

 Assign(F, FileName);
 {$I-}
 Reset(F);
 {$I+}
 If IOResult <> 0 Then Exit;

 InitSVGParseState;
 TotalContent := '';

 { Lire tout le fichier }
 While Not Eof(F) do Begin
  ReadLn(F, Line);
  TotalContent := TotalContent + Line + ' ';
 End;
 Close(F);

 { Parser les balises }
 I := 1;
 While I <= Length(TotalContent) do Begin
  { Chercher le dÃ©but d'une balise }
  While (I <= Length(TotalContent)) and (TotalContent[I] <> '<') do
   Inc(I);

  If I > Length(TotalContent) Then Break;
  TagStart := I;

  { Trouver la fin de la balise }
  While (I <= Length(TotalContent)) and (TotalContent[I] <> '>') do
   Inc(I);

  If I > Length(TotalContent) Then Break;
  TagEnd := I;

  Tag := Copy(TotalContent, TagStart + 1, TagEnd - TagStart - 1);
  Inc(I);

  { Extraire le nom de la balise }
  TagName := '';
  ContentStart := 1;
  While (ContentStart <= Length(Tag)) and (Tag[ContentStart] <> ' ') and
        (Tag[ContentStart] <> '/') and (Tag[ContentStart] <> '>') do Begin
   TagName := TagName + Tag[ContentStart];
   Inc(ContentStart);
  End;

  { Convertir en minuscules }
  For ContentStart := 1 to Length(TagName) do
   If (TagName[ContentStart] >= 'A') and (TagName[ContentStart] <= 'Z') Then
    TagName[ContentStart] := Chr(Ord(TagName[ContentStart]) + 32);

  { Traiter les diffÃ©rents types de balises }
  If TagName = 'rect' Then Begin
   If ParseSVGRect(Tag, Shape) Then Begin
    If ShapeCount < MAX_SHAPES Then Begin
     Inc(ShapeCount);
     Shapes[ShapeCount] := Shape;
    End;
   End;
  End
  Else If TagName = 'circle' Then Begin
   If ParseSVGCircle(Tag, Shape) Then Begin
    If ShapeCount < MAX_SHAPES Then Begin
     Inc(ShapeCount);
     Shapes[ShapeCount] := Shape;
    End;
   End;
  End
  Else If TagName = 'ellipse' Then Begin
   If ParseSVGEllipse(Tag, Shape) Then Begin
    If ShapeCount < MAX_SHAPES Then Begin
     Inc(ShapeCount);
     Shapes[ShapeCount] := Shape;
    End;
   End;
  End
  Else If TagName = 'line' Then Begin
   If ParseSVGLine(Tag, Shape) Then Begin
    If ShapeCount < MAX_SHAPES Then Begin
     Inc(ShapeCount);
     Shapes[ShapeCount] := Shape;
    End;
   End;
  End
  Else If TagName = 'polygon' Then Begin
   If ParseSVGPolygon(Tag, Shape, False) Then Begin
    If ShapeCount < MAX_SHAPES Then Begin
     Inc(ShapeCount);
     Shapes[ShapeCount] := Shape;
    End;
   End;
  End
  Else If TagName = 'polyline' Then Begin
   If ParseSVGPolygon(Tag, Shape, True) Then Begin
    If ShapeCount < MAX_SHAPES Then Begin
     Inc(ShapeCount);
     Shapes[ShapeCount] := Shape;
    End;
   End;
  End
  Else If TagName = 'path' Then Begin
   If ParseSVGPath(Tag, Shape) Then Begin
    If ShapeCount < MAX_SHAPES Then Begin
     Inc(ShapeCount);
     Shapes[ShapeCount] := Shape;
    End;
   End;
  End
  Else If TagName = 'text' Then Begin
   { Extraire le contenu texte }
   TextContent := '';
   While (I <= Length(TotalContent)) and (TotalContent[I] <> '<') do Begin
    If (TotalContent[I] <> #10) and (TotalContent[I] <> #13) Then
     TextContent := TextContent + TotalContent[I];
    Inc(I);
   End;
   { Supprimer les espaces au dÃ©but et Ã  la fin }
   While (Length(TextContent) > 0) and (TextContent[1] = ' ') do
    Delete(TextContent, 1, 1);
   While (Length(TextContent) > 0) and (TextContent[Length(TextContent)] = ' ') do
    Delete(TextContent, Length(TextContent), 1);

   If ParseSVGText(Tag, TextContent, Shape) Then Begin
    If ShapeCount < MAX_SHAPES Then Begin
     Inc(ShapeCount);
     Shapes[ShapeCount] := Shape;
    End;
   End;
  End;
 End;

 LoadSVGFile := True;
End;

{ Fonction pour dÃ©tecter si un fichier est un fichier SVG }
Function IsSVGFile(Const FileName: String): Boolean;
Var
 Ext: String;
 I: Integer;
Begin
 IsSVGFile := False;
 Ext := '';

 { Extraire l'extension }
 For I := Length(FileName) downto 1 do Begin
  If FileName[I] = '.' Then Begin
   Ext := Copy(FileName, I, Length(FileName) - I + 1);
   Break;
  End;
 End;

 { Convertir en minuscules }
 For I := 1 to Length(Ext) do
  If (Ext[I] >= 'A') and (Ext[I] <= 'Z') Then
   Ext[I] := Chr(Ord(Ext[I]) + 32);

 IsSVGFile := (Ext = '.svg');
End;

{ ============================================================================ }
{ === FIN DES FONCTIONS D'IMPORT SVG === }
{ ============================================================================ }

{ ============================================================================ }
{ === FONCTIONS D'EXPORT SVG === }
{ ============================================================================ }

{ Fonction pour convertir une couleur Pascal (palette 16 couleurs) en code hexadÃ©cimal SVG }
Function ColorToSVGHex(Color: Integer): String;
Begin
 Case Color of
  0:  ColorToSVGHex := '#000000';  { Noir }
  1:  ColorToSVGHex := '#0000AA';  { Bleu }
  2:  ColorToSVGHex := '#00AA00';  { Vert }
  3:  ColorToSVGHex := '#00AAAA';  { Cyan }
  4:  ColorToSVGHex := '#AA0000';  { Rouge }
  5:  ColorToSVGHex := '#AA00AA';  { Magenta }
  6:  ColorToSVGHex := '#AA5500';  { Marron }
  7:  ColorToSVGHex := '#AAAAAA';  { Gris clair }
  8:  ColorToSVGHex := '#555555';  { Gris foncÃ© }
  9:  ColorToSVGHex := '#5555FF';  { Bleu clair }
  10: ColorToSVGHex := '#55FF55';  { Vert clair }
  11: ColorToSVGHex := '#55FFFF';  { Cyan clair }
  12: ColorToSVGHex := '#FF5555';  { Rouge clair }
  13: ColorToSVGHex := '#FF55FF';  { Magenta clair }
  14: ColorToSVGHex := '#FFFF55';  { Jaune }
  15: ColorToSVGHex := '#FFFFFF';  { Blanc }
 Else
  ColorToSVGHex := '#000000';  { Noir par dÃ©faut }
 End;
End;

{ Fonction pour convertir le style de ligne en stroke-dasharray SVG }
Function LineStyleToSVGDash(LineStyle: Integer): String;
Begin
 Case LineStyle of
  0: LineStyleToSVGDash := '';                    { Solide }
  1: LineStyleToSVGDash := 'stroke-dasharray="5,5"';  { PointillÃ© }
  2: LineStyleToSVGDash := 'stroke-dasharray="10,5"'; { Tirets }
  3: LineStyleToSVGDash := 'stroke-dasharray="10,5,2,5"'; { Tiret-point }
 Else
  LineStyleToSVGDash := '';
 End;
End;

{ Fonction pour gÃ©nÃ©rer les attributs de style CSS pour une forme }
Function ShapeToSVGStyle(Const Shape: TShapeObject): String;
Var
 Style: String;
Begin
 Style := 'style="';

 { Couleur de remplissage }
 If Shape.FillColor >= 0 Then
  Style := Style + 'fill:' + ColorToSVGHex(Shape.FillColor) + ';'
 Else
  Style := Style + 'fill:none;';

 { Couleur de contour }
 If Shape.LineColor >= 0 Then
  Style := Style + 'stroke:' + ColorToSVGHex(Shape.LineColor) + ';'
 Else
  Style := Style + 'stroke:none;';

 { Ã‰paisseur de ligne }
 If Shape.LineWidth > 0 Then Begin
  Style := Style + 'stroke-width:';
  { Convertir Integer en String manuellement }
  If Shape.LineWidth < 10 Then
   Style := Style + Chr(Ord('0') + Shape.LineWidth)
  Else Begin
   Style := Style + Chr(Ord('0') + (Shape.LineWidth Div 10));
   Style := Style + Chr(Ord('0') + (Shape.LineWidth Mod 10));
  End;
  Style := Style + ';';
 End;

 Style := Style + '"';

 { Ajouter le style de ligne si nÃ©cessaire }
 If Shape.LineStyle > 0 Then
  Style := Style + ' ' + LineStyleToSVGDash(Shape.LineStyle);

 ShapeToSVGStyle := Style;
End;

{ Fonction pour convertir un entier en chaÃ®ne }
Function IntToStrSVG(N: Integer): String;
Var
 S: String;
 Neg: Boolean;
Begin
 If N = 0 Then Begin
  IntToStrSVG := '0';
  Exit;
 End;

 Neg := N < 0;
 If Neg Then N := -N;

 S := '';
 While N > 0 do Begin
  S := Chr(Ord('0') + (N Mod 10)) + S;
  N := N Div 10;
 End;

 If Neg Then S := '-' + S;
 IntToStrSVG := S;
End;

{ ProcÃ©dure pour Ã©crire un rectangle en SVG }
Procedure WriteSVGRect(Var F: Text; Const Shape: TShapeObject);
Var
 X, Y, W, H: Integer;
Begin
 X := Shape.X1;
 Y := Shape.Y1;
 W := Shape.X2 - Shape.X1;
 H := Shape.Y2 - Shape.Y1;

 If W < 0 Then Begin X := Shape.X2; W := -W; End;
 If H < 0 Then Begin Y := Shape.Y2; H := -H; End;

 WriteLn(F, '  <rect x="' + IntToStrSVG(X) + '" y="' + IntToStrSVG(Y) +
            '" width="' + IntToStrSVG(W) + '" height="' + IntToStrSVG(H) +
            '" ' + ShapeToSVGStyle(Shape) + ' />');
End;

{ ProcÃ©dure pour Ã©crire une ellipse en SVG }
Procedure WriteSVGEllipse(Var F: Text; Const Shape: TShapeObject);
Var
 CX, CY, RX, RY: Integer;
Begin
 CX := (Shape.X1 + Shape.X2) Div 2;
 CY := (Shape.Y1 + Shape.Y2) Div 2;
 RX := Abs(Shape.X2 - Shape.X1) Div 2;
 RY := Abs(Shape.Y2 - Shape.Y1) Div 2;

 { Si RX = RY, Ã©crire un cercle }
 If RX = RY Then
  WriteLn(F, '  <circle cx="' + IntToStrSVG(CX) + '" cy="' + IntToStrSVG(CY) +
             '" r="' + IntToStrSVG(RX) + '" ' + ShapeToSVGStyle(Shape) + ' />')
 Else
  WriteLn(F, '  <ellipse cx="' + IntToStrSVG(CX) + '" cy="' + IntToStrSVG(CY) +
             '" rx="' + IntToStrSVG(RX) + '" ry="' + IntToStrSVG(RY) +
             '" ' + ShapeToSVGStyle(Shape) + ' />');
End;

{ ProcÃ©dure pour Ã©crire une ligne en SVG }
Procedure WriteSVGLine(Var F: Text; Const Shape: TShapeObject);
Begin
 WriteLn(F, '  <line x1="' + IntToStrSVG(Shape.X1) + '" y1="' + IntToStrSVG(Shape.Y1) +
            '" x2="' + IntToStrSVG(Shape.X2) + '" y2="' + IntToStrSVG(Shape.Y2) +
            '" ' + ShapeToSVGStyle(Shape) + ' />');
End;

{ ProcÃ©dure pour Ã©crire un polygone en SVG }
Procedure WriteSVGPolygon(Var F: Text; Const Shape: TShapeObject);
Var
 Points: String;
 I: Integer;
Begin
 If Shape.PointCount < 2 Then Exit;

 Points := '';
 For I := 1 to Shape.PointCount do Begin
  If I > 1 Then Points := Points + ' ';
  Points := Points + IntToStrSVG(Shape.Points[I].X) + ',' + IntToStrSVG(Shape.Points[I].Y);
 End;

 WriteLn(F, '  <polygon points="' + Points + '" ' + ShapeToSVGStyle(Shape) + ' />');
End;

{ Echappement XML basique pour le contenu textuel d'un noeud SVG. }
Function XMLEscape(Const S: String): String;
Var
 I: Integer;
 R: String;
 C: Char;
Begin
 R := '';
 For I := 1 to Length(S) do Begin
  C := S[I];
  Case C of
   '&': R := R + '&amp;';
   '<': R := R + '&lt;';
   '>': R := R + '&gt;';
   '"': R := R + '&quot;';
   '''': R := R + '&apos;';
  Else
   R := R + C;
  End;
 End;
 XMLEscape := R;
End;

{ ProcÃ©dure pour Ã©crire un texte en SVG }
Procedure WriteSVGText(Var F: Text; Const Shape: TShapeObject);
Var
 Style: String;
Begin
 Style := 'style="';

 { Couleur du texte }
 If Shape.FillColor >= 0 Then
  Style := Style + 'fill:' + ColorToSVGHex(Shape.FillColor) + ';'
 Else
  Style := Style + 'fill:#000000;';

 { Taille de police estimÃ©e }
 Style := Style + 'font-size:14px;font-family:sans-serif;"';

 WriteLn(F, '  <text x="' + IntToStrSVG(Shape.X1) + '" y="' + IntToStrSVG(Shape.Y2) +
            '" ' + Style + '>' + XMLEscape(Shape.Text) + '</text>');
End;

{ ProcÃ©dure pour Ã©crire un connecteur en SVG (comme une ligne avec des marqueurs) }
Procedure WriteSVGConnector(Var F: Text; Const Shape: TShapeObject);
Begin
 { Les connecteurs sont exportÃ©s comme des lignes simples }
 WriteLn(F, '  <line x1="' + IntToStrSVG(Shape.X1) + '" y1="' + IntToStrSVG(Shape.Y1) +
            '" x2="' + IntToStrSVG(Shape.X2) + '" y2="' + IntToStrSVG(Shape.Y2) +
            '" ' + ShapeToSVGStyle(Shape) + ' marker-end="url(#arrowhead)" />');
End;

{ ProcÃ©dure pour Ã©crire une courbe de BÃ©zier en SVG }
{ - 4 points     -> 1 segment cubique  (M c1 c2 c3)               }
{ - 4+3k points  -> k+1 segments cubiques (M c1 c2 c3 c4 c5 c6 ...)}
{ - sinon        -> polyligne par segments droits                 }
Procedure WriteSVGBezier(Var F: Text; Const Shape: TShapeObject);
Var
 PathData: String;
 I, N: Integer;
Begin
 N := Shape.PointCount;
 If N < 2 Then Exit;

 PathData := 'M' + IntToStrSVG(Shape.Points[1].X) + ',' + IntToStrSVG(Shape.Points[1].Y);

 If (N >= 4) And (((N - 1) Mod 3) = 0) Then Begin
  { Cubic Bezier : groupes de 3 points (deux controles + ancre) }
  I := 2;
  While I + 2 <= N do Begin
   PathData := PathData + ' C' +
               IntToStrSVG(Shape.Points[I].X)   + ',' + IntToStrSVG(Shape.Points[I].Y) + ' ' +
               IntToStrSVG(Shape.Points[I+1].X) + ',' + IntToStrSVG(Shape.Points[I+1].Y) + ' ' +
               IntToStrSVG(Shape.Points[I+2].X) + ',' + IntToStrSVG(Shape.Points[I+2].Y);
   I := I + 3;
  End;
 End
 Else Begin
  { Repli : polyligne }
  For I := 2 to N do
   PathData := PathData + ' L' + IntToStrSVG(Shape.Points[I].X) + ',' + IntToStrSVG(Shape.Points[I].Y);
 End;

 WriteLn(F, '  <path d="' + PathData + '" ' + ShapeToSVGStyle(Shape) + ' />');
End;

{ Fonction principale pour sauvegarder un fichier SVG }
Function SaveSVGFile(Const FileName: String): Boolean;
Var
 F: Text;
 I: Integer;
 MinX, MinY, MaxX, MaxY: Integer;
 Width, Height: Integer;
Begin
 SaveSVGFile := False;

 Assign(F, FileName);
 {$I-}
 Rewrite(F);
 {$I+}
 If IOResult <> 0 Then Exit;

 { Calculer les dimensions du dessin }
 MinX := 32767; MinY := 32767;
 MaxX := 0; MaxY := 0;

 For I := 1 to ShapeCount do Begin
  If Shapes[I].X1 < MinX Then MinX := Shapes[I].X1;
  If Shapes[I].Y1 < MinY Then MinY := Shapes[I].Y1;
  If Shapes[I].X2 < MinX Then MinX := Shapes[I].X2;
  If Shapes[I].Y2 < MinY Then MinY := Shapes[I].Y2;
  If Shapes[I].X1 > MaxX Then MaxX := Shapes[I].X1;
  If Shapes[I].Y1 > MaxY Then MaxY := Shapes[I].Y1;
  If Shapes[I].X2 > MaxX Then MaxX := Shapes[I].X2;
  If Shapes[I].Y2 > MaxY Then MaxY := Shapes[I].Y2;
 End;

 If ShapeCount = 0 Then Begin
  Width := 800;
  Height := 600;
 End
 Else Begin
  Width := MaxX - MinX + 20;
  Height := MaxY - MinY + 20;
  If Width < 100 Then Width := 100;
  If Height < 100 Then Height := 100;
 End;

 { Ã‰crire l'en-tÃªte XML et SVG }
 WriteLn(F, '<?xml version="1.0" encoding="UTF-8"?>');
 WriteLn(F, '<svg xmlns="http://www.w3.org/2000/svg" version="1.1"');
 WriteLn(F, '     width="' + IntToStrSVG(Width) + '" height="' + IntToStrSVG(Height) + '"');
 WriteLn(F, '     viewBox="' + IntToStrSVG(MinX - 10) + ' ' + IntToStrSVG(MinY - 10) +
            ' ' + IntToStrSVG(Width) + ' ' + IntToStrSVG(Height) + '">');
 WriteLn(F, '');

 { DÃ©finir les marqueurs pour les connecteurs }
 WriteLn(F, '  <defs>');
 WriteLn(F, '    <marker id="arrowhead" markerWidth="10" markerHeight="7" refX="10" refY="3.5" orient="auto">');
 WriteLn(F, '      <polygon points="0 0, 10 3.5, 0 7" fill="#000000" />');
 WriteLn(F, '    </marker>');
 WriteLn(F, '  </defs>');
 WriteLn(F, '');

 { Ajouter un commentaire avec les informations du document }
 WriteLn(F, '  <!-- Generated by CloneDRAW VISIO -->');
 WriteLn(F, '');

 { Ã‰crire chaque forme }
 For I := 1 to ShapeCount do Begin
  Case Shapes[I].ShapeType of
   stRectangle: WriteSVGRect(F, Shapes[I]);
   stEllipse: WriteSVGEllipse(F, Shapes[I]);
   stLine: WriteSVGLine(F, Shapes[I]);
   stConnector: WriteSVGConnector(F, Shapes[I]);
   stText: WriteSVGText(F, Shapes[I]);
   stPolygon: WriteSVGPolygon(F, Shapes[I]);
   stBezier: WriteSVGBezier(F, Shapes[I]);
   { stImage n'est pas exportÃ© directement car nÃ©cessite l'inclusion de l'image }
  End;
 End;

 { Fermer le document SVG }
 WriteLn(F, '');
 WriteLn(F, '</svg>');

 Close(F);
 SaveSVGFile := True;
End;

{ ============================================================================ }
{ === FIN DES FONCTIONS D'EXPORT SVG === }
{ ============================================================================ }

{ ============================================================================ }
{ === FONCTIONS D'EXPORT BMP === }
{ ============================================================================ }

{ Constantes pour le format BMP }
Const
 BMP_SIGNATURE = $4D42;  { 'BM' en little-endian }
 BI_RGB = 0;             { Pas de compression }

{ Fonction pour calculer la taille d'une ligne BMP avec padding (multiple de 4 octets) }
Function GetBMPRowSize(Width, BitsPerPixel: Integer): LongInt;
Var
 RowBits: LongInt;
Begin
 RowBits := LongInt(Width) * LongInt(BitsPerPixel);
 GetBMPRowSize := ((RowBits + 31) Div 32) * 4;
End;

{ ProcÃ©dure pour Ã©crire un Word (2 octets) en little-endian }
Procedure WriteWord(Var F: File; W: Word);
Var
 B: Array[0..1] of Byte;
Begin
 B[0] := Lo(W);
 B[1] := Hi(W);
 BlockWrite(F, B, 2);
End;

{ ProcÃ©dure pour Ã©crire un LongInt (4 octets) en little-endian }
Procedure WriteDWord(Var F: File; D: LongInt);
Var
 B: Array[0..3] of Byte;
Begin
 B[0] := D And $FF;
 B[1] := (D Shr 8) And $FF;
 B[2] := (D Shr 16) And $FF;
 B[3] := (D Shr 24) And $FF;
 BlockWrite(F, B, 4);
End;

{ ProcÃ©dure pour Ã©crire un octet }
Procedure WriteByte(Var F: File; B: Byte);
Begin
 BlockWrite(F, B, 1);
End;

{ Fonction pour convertir une couleur palette en RGB (R, G, B) }
Procedure PaletteToRGB(Color: Integer; Var R, G, B: Byte);
Begin
 Case Color of
  0:  Begin R := 0;   G := 0;   B := 0;   End;  { Noir }
  1:  Begin R := 0;   G := 0;   B := 170; End;  { Bleu }
  2:  Begin R := 0;   G := 170; B := 0;   End;  { Vert }
  3:  Begin R := 0;   G := 170; B := 170; End;  { Cyan }
  4:  Begin R := 170; G := 0;   B := 0;   End;  { Rouge }
  5:  Begin R := 170; G := 0;   B := 170; End;  { Magenta }
  6:  Begin R := 170; G := 85;  B := 0;   End;  { Marron }
  7:  Begin R := 170; G := 170; B := 170; End;  { Gris clair }
  8:  Begin R := 85;  G := 85;  B := 85;  End;  { Gris foncÃ© }
  9:  Begin R := 85;  G := 85;  B := 255; End;  { Bleu clair }
  10: Begin R := 85;  G := 255; B := 85;  End;  { Vert clair }
  11: Begin R := 85;  G := 255; B := 255; End;  { Cyan clair }
  12: Begin R := 255; G := 85;  B := 85;  End;  { Rouge clair }
  13: Begin R := 255; G := 85;  B := 255; End;  { Magenta clair }
  14: Begin R := 255; G := 255; B := 85;  End;  { Jaune }
  15: Begin R := 255; G := 255; B := 255; End;  { Blanc }
 Else
  Begin R := 0; G := 0; B := 0; End;  { Noir par dÃ©faut }
 End;
End;

{ ProcÃ©dure pour Ã©crire l'en-tÃªte BMP (BITMAPFILEHEADER + BITMAPINFOHEADER) }
Procedure WriteBMPHeader(Var F: File; Width, Height: Integer; BitsPerPixel: Integer;
                         PaletteSize: Integer);
Var
 RowSize: LongInt;
 ImageSize: LongInt;
 FileSize: LongInt;
 OffsetBits: LongInt;
 HeaderSize: LongInt;
Begin
 RowSize := GetBMPRowSize(Width, BitsPerPixel);
 ImageSize := RowSize * LongInt(Height);
 HeaderSize := 14 + 40;  { BITMAPFILEHEADER + BITMAPINFOHEADER }
 OffsetBits := HeaderSize + (LongInt(PaletteSize) * 4);
 FileSize := OffsetBits + ImageSize;

 { BITMAPFILEHEADER (14 octets) }
 WriteWord(F, BMP_SIGNATURE);   { bfType: 'BM' }
 WriteDWord(F, FileSize);       { bfSize: taille totale du fichier }
 WriteWord(F, 0);               { bfReserved1 }
 WriteWord(F, 0);               { bfReserved2 }
 WriteDWord(F, OffsetBits);     { bfOffBits: offset vers les donnÃ©es }

 { BITMAPINFOHEADER (40 octets) }
 WriteDWord(F, 40);             { biSize: taille de l'en-tÃªte }
 WriteDWord(F, Width);          { biWidth }
 WriteDWord(F, Height);         { biHeight (positif = bottom-up) }
 WriteWord(F, 1);               { biPlanes }
 WriteWord(F, BitsPerPixel);    { biBitCount }
 WriteDWord(F, BI_RGB);         { biCompression }
 WriteDWord(F, ImageSize);      { biSizeImage }
 WriteDWord(F, 2835);           { biXPelsPerMeter (72 DPI) }
 WriteDWord(F, 2835);           { biYPelsPerMeter (72 DPI) }
 WriteDWord(F, PaletteSize);    { biClrUsed }
 WriteDWord(F, 0);              { biClrImportant }
End;

{ ProcÃ©dure pour Ã©crire la palette 16 couleurs standard }
Procedure WritePalette16(Var F: File);
Var
 I: Integer;
 R, G, B: Byte;
Begin
 For I := 0 to 15 do Begin
  PaletteToRGB(I, R, G, B);
  WriteByte(F, B);  { Bleu }
  WriteByte(F, G);  { Vert }
  WriteByte(F, R);  { Rouge }
  WriteByte(F, 0);  { RÃ©servÃ© }
 End;
End;

{ ProcÃ©dure pour Ã©crire la palette 256 couleurs (16 + niveaux de gris) }
Procedure WritePalette256(Var F: File);
Var
 I: Integer;
 R, G, B: Byte;
 Gray: Byte;
Begin
 { Les 16 premiÃ¨res couleurs sont la palette standard }
 For I := 0 to 15 do Begin
  PaletteToRGB(I, R, G, B);
  WriteByte(F, B);
  WriteByte(F, G);
  WriteByte(F, R);
  WriteByte(F, 0);
 End;

 { Les couleurs 16-255 sont des niveaux de gris }
 For I := 16 to 255 do Begin
  Gray := (I - 16) + (I - 16) Div 15;  { Distribution des niveaux de gris }
  WriteByte(F, Gray);
  WriteByte(F, Gray);
  WriteByte(F, Gray);
  WriteByte(F, 0);
 End;
End;

{ ProcÃ©dure pour Ã©crire la palette monochrome (noir et blanc) }
Procedure WritePalette2(Var F: File);
Begin
 { Couleur 0: Noir }
 WriteByte(F, 0);
 WriteByte(F, 0);
 WriteByte(F, 0);
 WriteByte(F, 0);

 { Couleur 1: Blanc }
 WriteByte(F, 255);
 WriteByte(F, 255);
 WriteByte(F, 255);
 WriteByte(F, 0);
End;

{ Type pour un buffer de pixels }
Type
 TPixelBuffer = Array[0..2047, 0..2047] of Byte;
 PPixelBuffer = ^TPixelBuffer;

Var
 PixelBuffer: PPixelBuffer;
 BufferWidth, BufferHeight: Integer;
 { Selecteur de mode d'export raster : True = capture canvas BGI (WYSIWYG),  }
 { False = re-rendu depuis Shapes[] (rendu propre, sans residus dialogue).   }
 ExportFromScreen: Boolean;

{ Forward : helper unifie de preparation du PixelBuffer (defini plus bas). }
Function PrepareExportBuffer(Var Width, Height: Integer): Boolean; Forward;

{ Initialiser le buffer de pixels }
Procedure InitPixelBuffer(Width, Height: Integer);
Begin
 BufferWidth := Width;
 BufferHeight := Height;
 If BufferWidth > 2048 Then BufferWidth := 2048;
 If BufferHeight > 2048 Then BufferHeight := 2048;
 New(PixelBuffer);
 FillChar(PixelBuffer^, SizeOf(TPixelBuffer), 15);  { Remplir de blanc }
End;

{ LibÃ©rer le buffer de pixels }
Procedure FreePixelBuffer;
Begin
 If PixelBuffer <> Nil Then Begin
  Dispose(PixelBuffer);
  PixelBuffer := Nil;
 End;
End;

{ DÃ©finir un pixel dans le buffer }
Procedure SetBufferPixel(X, Y: Integer; Color: Byte);
Begin
 If (X >= 0) And (X < BufferWidth) And (Y >= 0) And (Y < BufferHeight) Then
  PixelBuffer^[Y, X] := Color;
End;

{ Dessiner une ligne dans le buffer (algorithme de Bresenham) }
Procedure DrawBufferLine(X1, Y1, X2, Y2: Integer; Color: Byte);
Var
 DX, DY, SX, SY, Err, E2: Integer;
Begin
 DX := Abs(X2 - X1);
 DY := Abs(Y2 - Y1);
 If X1 < X2 Then SX := 1 Else SX := -1;
 If Y1 < Y2 Then SY := 1 Else SY := -1;
 Err := DX - DY;

 While True do Begin
  SetBufferPixel(X1, Y1, Color);
  If (X1 = X2) And (Y1 = Y2) Then Break;
  E2 := 2 * Err;
  If E2 > -DY Then Begin
   Err := Err - DY;
   X1 := X1 + SX;
  End;
  If E2 < DX Then Begin
   Err := Err + DX;
   Y1 := Y1 + SY;
  End;
 End;
End;

{ Dessiner un rectangle plein dans le buffer }
Procedure DrawBufferRect(X1, Y1, X2, Y2: Integer; FillColor, LineColor: Byte);
Var
 X, Y, Temp: Integer;
Begin
 { S'assurer que X1 <= X2 et Y1 <= Y2 }
 If X1 > X2 Then Begin Temp := X1; X1 := X2; X2 := Temp; End;
 If Y1 > Y2 Then Begin Temp := Y1; Y1 := Y2; Y2 := Temp; End;

 { Remplissage }
 If FillColor < 255 Then
  For Y := Y1 to Y2 do
   For X := X1 to X2 do
    SetBufferPixel(X, Y, FillColor);

 { Contour }
 If LineColor < 255 Then Begin
  For X := X1 to X2 do Begin
   SetBufferPixel(X, Y1, LineColor);
   SetBufferPixel(X, Y2, LineColor);
  End;
  For Y := Y1 to Y2 do Begin
   SetBufferPixel(X1, Y, LineColor);
   SetBufferPixel(X2, Y, LineColor);
  End;
 End;
End;

{ Dessiner une ellipse dans le buffer (algorithme de Bresenham) }
Procedure DrawBufferEllipse(CX, CY, RX, RY: Integer; FillColor, LineColor: Byte);
Var
 X, Y: Integer;
 RX2, RY2: LongInt;
 FX, FY: LongInt;
 P: LongInt;
 PX, PY: Integer;
Begin
 If (RX <= 0) Or (RY <= 0) Then Exit;

 RX2 := LongInt(RX) * LongInt(RX);
 RY2 := LongInt(RY) * LongInt(RY);

 { Remplissage simple avec des lignes horizontales }
 If FillColor < 255 Then Begin
  For Y := -RY to RY do Begin
   FX := Round(Sqrt((1 - (LongInt(Y) * LongInt(Y)) / RY2) * RX2));
   For X := CX - FX to CX + FX do
    SetBufferPixel(X, CY + Y, FillColor);
  End;
 End;

 { Contour - Algorithme de Bresenham pour ellipse }
 If LineColor < 255 Then Begin
  X := 0;
  Y := RY;
  P := RY2 - RX2 * RY + RX2 Div 4;

  While 2 * RY2 * X <= 2 * RX2 * Y do Begin
   SetBufferPixel(CX + X, CY + Y, LineColor);
   SetBufferPixel(CX - X, CY + Y, LineColor);
   SetBufferPixel(CX + X, CY - Y, LineColor);
   SetBufferPixel(CX - X, CY - Y, LineColor);

   If P < 0 Then Begin
    X := X + 1;
    P := P + 2 * RY2 * X + RY2;
   End
   Else Begin
    X := X + 1;
    Y := Y - 1;
    P := P + 2 * RY2 * X - 2 * RX2 * Y + RY2;
   End;
  End;

  P := RY2 * (X * X + X) + RX2 * (Y - 1) * (Y - 1) - RX2 * RY2;
  While Y >= 0 do Begin
   SetBufferPixel(CX + X, CY + Y, LineColor);
   SetBufferPixel(CX - X, CY + Y, LineColor);
   SetBufferPixel(CX + X, CY - Y, LineColor);
   SetBufferPixel(CX - X, CY - Y, LineColor);

   If P > 0 Then Begin
    Y := Y - 1;
    P := P - 2 * RX2 * Y + RX2;
   End
   Else Begin
    X := X + 1;
    Y := Y - 1;
    P := P + 2 * RY2 * X - 2 * RX2 * Y + RX2;
   End;
  End;
 End;
End;

{ Dessiner un polygone dans le buffer }
Procedure DrawBufferPolygon(Const Points: TPointArray; PointCount: Integer;
                            FillColor, LineColor: Byte);
Var
 I: Integer;
Begin
 If PointCount < 2 Then Exit;

 { Dessiner les lignes du contour }
 If LineColor < 255 Then Begin
  For I := 1 to PointCount - 1 do
   DrawBufferLine(Points[I].X, Points[I].Y, Points[I+1].X, Points[I+1].Y, LineColor);
  { Fermer le polygone }
  DrawBufferLine(Points[PointCount].X, Points[PointCount].Y,
                 Points[1].X, Points[1].Y, LineColor);
 End;
End;

{ Rendre les formes dans le buffer de pixels }
Procedure RenderShapesToBuffer;
Var
 I: Integer;
 CX, CY, RX, RY: Integer;
 FC, LC: Byte;
Begin
 For I := 1 to ShapeCount do Begin
  { Convertir les couleurs (utiliser 15/blanc si nÃ©gatif) }
  If Shapes[I].FillColor >= 0 Then FC := Shapes[I].FillColor Else FC := 255;
  If Shapes[I].LineColor >= 0 Then LC := Shapes[I].LineColor Else LC := 0;

  Case Shapes[I].ShapeType of
   stRectangle:
    DrawBufferRect(Shapes[I].X1, Shapes[I].Y1, Shapes[I].X2, Shapes[I].Y2, FC, LC);

   stEllipse: Begin
    CX := (Shapes[I].X1 + Shapes[I].X2) Div 2;
    CY := (Shapes[I].Y1 + Shapes[I].Y2) Div 2;
    RX := Abs(Shapes[I].X2 - Shapes[I].X1) Div 2;
    RY := Abs(Shapes[I].Y2 - Shapes[I].Y1) Div 2;
    DrawBufferEllipse(CX, CY, RX, RY, FC, LC);
   End;

   stLine, stConnector:
    DrawBufferLine(Shapes[I].X1, Shapes[I].Y1, Shapes[I].X2, Shapes[I].Y2, LC);

   stPolygon, stBezier:
    DrawBufferPolygon(Shapes[I].Points, Shapes[I].PointCount, FC, LC);
  End;
 End;
End;

{ Exporter en BMP 24-bit (True Color) }
Function SaveBMP24Bit(Const FileName: String; Width, Height: Integer): Boolean;
Var
 F: File;
 X, Y: Integer;
 R, G, B: Byte;
 RowSize: LongInt;
 Padding: Integer;
 PadByte: Byte;
Begin
 SaveBMP24Bit := False;
 PadByte := 0;

 Assign(F, FileName);
 {$I-}
 Rewrite(F, 1);
 {$I+}
 If IOResult <> 0 Then Exit;

 RowSize := GetBMPRowSize(Width, 24);
 Padding := RowSize - (Width * 3);

 WriteBMPHeader(F, Width, Height, 24, 0);

 { Ã‰crire les pixels (bottom-up) }
 For Y := Height - 1 downto 0 do Begin
  For X := 0 to Width - 1 do Begin
   PaletteToRGB(PixelBuffer^[Y, X], R, G, B);
   WriteByte(F, B);
   WriteByte(F, G);
   WriteByte(F, R);
  End;
  { Padding }
  For X := 1 to Padding do
   WriteByte(F, PadByte);
 End;

 Close(F);
 SaveBMP24Bit := True;
End;

{ Exporter en BMP 8-bit (256 couleurs) }
Function SaveBMP8Bit(Const FileName: String; Width, Height: Integer): Boolean;
Var
 F: File;
 X, Y: Integer;
 RowSize: LongInt;
 Padding: Integer;
 PadByte: Byte;
Begin
 SaveBMP8Bit := False;
 PadByte := 0;

 Assign(F, FileName);
 {$I-}
 Rewrite(F, 1);
 {$I+}
 If IOResult <> 0 Then Exit;

 RowSize := GetBMPRowSize(Width, 8);
 Padding := RowSize - Width;

 WriteBMPHeader(F, Width, Height, 8, 256);
 WritePalette256(F);

 { Ã‰crire les pixels (bottom-up) }
 For Y := Height - 1 downto 0 do Begin
  For X := 0 to Width - 1 do
   WriteByte(F, PixelBuffer^[Y, X]);
  { Padding }
  For X := 1 to Padding do
   WriteByte(F, PadByte);
 End;

 Close(F);
 SaveBMP8Bit := True;
End;

{ Exporter en BMP 4-bit (16 couleurs) }
Function SaveBMP4Bit(Const FileName: String; Width, Height: Integer): Boolean;
Var
 F: File;
 X, Y: Integer;
 RowSize: LongInt;
 BytesPerRow: Integer;
 Padding: Integer;
 PadByte: Byte;
 PixelPair: Byte;
Begin
 SaveBMP4Bit := False;
 PadByte := 0;

 Assign(F, FileName);
 {$I-}
 Rewrite(F, 1);
 {$I+}
 If IOResult <> 0 Then Exit;

 RowSize := GetBMPRowSize(Width, 4);
 BytesPerRow := (Width + 1) Div 2;
 Padding := RowSize - BytesPerRow;

 WriteBMPHeader(F, Width, Height, 4, 16);
 WritePalette16(F);

 { Ã‰crire les pixels (bottom-up, 2 pixels par octet) }
 For Y := Height - 1 downto 0 do Begin
  X := 0;
  While X < Width do Begin
   { Premier pixel (4 bits de poids fort) }
   PixelPair := (PixelBuffer^[Y, X] And $0F) Shl 4;
   { DeuxiÃ¨me pixel (4 bits de poids faible) }
   If X + 1 < Width Then
    PixelPair := PixelPair Or (PixelBuffer^[Y, X + 1] And $0F);
   WriteByte(F, PixelPair);
   X := X + 2;
  End;
  { Padding }
  For X := 1 to Padding do
   WriteByte(F, PadByte);
 End;

 Close(F);
 SaveBMP4Bit := True;
End;

{ Exporter en BMP 1-bit (monochrome) }
Function SaveBMP1Bit(Const FileName: String; Width, Height: Integer): Boolean;
Var
 F: File;
 X, Y: Integer;
 RowSize: LongInt;
 BytesPerRow: Integer;
 Padding: Integer;
 PadByte: Byte;
 ByteVal: Byte;
 BitPos: Integer;
Begin
 SaveBMP1Bit := False;
 PadByte := 0;

 Assign(F, FileName);
 {$I-}
 Rewrite(F, 1);
 {$I+}
 If IOResult <> 0 Then Exit;

 RowSize := GetBMPRowSize(Width, 1);
 BytesPerRow := (Width + 7) Div 8;
 Padding := RowSize - BytesPerRow;

 WriteBMPHeader(F, Width, Height, 1, 2);
 WritePalette2(F);

 { Ã‰crire les pixels (bottom-up, 8 pixels par octet) }
 For Y := Height - 1 downto 0 do Begin
  ByteVal := 0;
  BitPos := 7;

  For X := 0 to Width - 1 do Begin
   { Convertir en noir (0) ou blanc (1) basÃ© sur la luminositÃ© }
   If PixelBuffer^[Y, X] >= 8 Then  { Couleurs 8-15 sont "claires" }
    ByteVal := ByteVal Or (1 Shl BitPos);

   Dec(BitPos);
   If BitPos < 0 Then Begin
    WriteByte(F, ByteVal);
    ByteVal := 0;
    BitPos := 7;
   End;
  End;

  { Ã‰crire le dernier octet partiel si nÃ©cessaire }
  If BitPos < 7 Then
   WriteByte(F, ByteVal);

  { Padding }
  For X := 1 to Padding do
   WriteByte(F, PadByte);
 End;

 Close(F);
 SaveBMP1Bit := True;
End;

{ Fonction principale pour sauvegarder un fichier BMP }
{ BitsPerPixel peut Ãªtre 1, 4, 8, ou 24 }
Function SaveBMPFile(Const FileName: String; BitsPerPixel: Integer): Boolean;
Var
 Width, Height: Integer;
Begin
 SaveBMPFile := False;
 If Not PrepareExportBuffer(Width, Height) Then Exit;

 { Exporter selon le nombre de bits }
 Case BitsPerPixel of
  1:  SaveBMPFile := SaveBMP1Bit(FileName, Width, Height);
  4:  SaveBMPFile := SaveBMP4Bit(FileName, Width, Height);
  8:  SaveBMPFile := SaveBMP8Bit(FileName, Width, Height);
  24: SaveBMPFile := SaveBMP24Bit(FileName, Width, Height);
 Else
  SaveBMPFile := SaveBMP24Bit(FileName, Width, Height);  { Par dÃ©faut: 24-bit }
 End;

 FreePixelBuffer;
End;

{ ============================================================================ }
{ === FIN DES FONCTIONS D'EXPORT BMP === }
{ ============================================================================ }

{ ============================================================================ }
{ === FONCTIONS D'EXPORT GIF === }
{ ============================================================================ }

{ Constantes pour le format GIF }
Const
 GIF_SIGNATURE = 'GIF';
 GIF_VERSION = '89a';
 GIF_TRAILER = $3B;         { Terminateur GIF ';' }
 GIF_IMAGE_SEPARATOR = $2C; { SÃ©parateur d'image ',' }
 GIF_EXTENSION = $21;       { Extension '!' }
 GIF_GCE_LABEL = $F9;       { Label Graphics Control Extension }
 GIF_MAX_CODE_SIZE = 12;    { Taille maximale du code LZW }

{ Types pour l'encodage LZW }
Type
 TLZWCode = Integer;
 TLZWTable = Array[0..4095] of Record
  Prefix: Integer;
  Suffix: Byte;
 End;

Var
 LZWTable: TLZWTable;
 LZWCodeSize: Integer;
 LZWNextCode: Integer;
 LZWClearCode: Integer;
 LZWEOICode: Integer;
 LZWBitBuffer: LongInt;
 LZWBitsInBuffer: Integer;
 LZWByteBuffer: Array[0..254] of Byte;
 LZWByteCount: Integer;

{ ProcÃ©dure pour initialiser la table LZW }
Procedure InitLZWTable(ColorBits: Integer);
Var
 I: Integer;
Begin
 LZWCodeSize := ColorBits + 1;
 LZWClearCode := 1 Shl ColorBits;
 LZWEOICode := LZWClearCode + 1;
 LZWNextCode := LZWEOICode + 1;
 LZWBitBuffer := 0;
 LZWBitsInBuffer := 0;
 LZWByteCount := 0;

 { Initialiser les codes de base (0 Ã  255) }
 For I := 0 to LZWClearCode - 1 do Begin
  LZWTable[I].Prefix := -1;
  LZWTable[I].Suffix := I;
 End;
End;

{ ProcÃ©dure pour rÃ©initialiser la table LZW }
Procedure ResetLZWTable(ColorBits: Integer);
Begin
 LZWCodeSize := ColorBits + 1;
 LZWNextCode := LZWEOICode + 1;
End;

{ ProcÃ©dure pour Ã©crire un sous-bloc de donnÃ©es }
Procedure FlushLZWByteBuffer(Var F: File);
Begin
 If LZWByteCount > 0 Then Begin
  WriteByte(F, LZWByteCount);
  BlockWrite(F, LZWByteBuffer, LZWByteCount);
  LZWByteCount := 0;
 End;
End;

{ ProcÃ©dure pour Ã©crire un code LZW }
Procedure WriteLZWCode(Var F: File; Code: Integer);
Begin
 LZWBitBuffer := LZWBitBuffer Or (LongInt(Code) Shl LZWBitsInBuffer);
 LZWBitsInBuffer := LZWBitsInBuffer + LZWCodeSize;

 While LZWBitsInBuffer >= 8 do Begin
  LZWByteBuffer[LZWByteCount] := LZWBitBuffer And $FF;
  Inc(LZWByteCount);
  LZWBitBuffer := LZWBitBuffer Shr 8;
  LZWBitsInBuffer := LZWBitsInBuffer - 8;

  If LZWByteCount >= 254 Then
   FlushLZWByteBuffer(F);
 End;
End;

{ ProcÃ©dure pour terminer l'Ã©criture LZW }
Procedure FinishLZWOutput(Var F: File);
Begin
 { Ã‰crire les bits restants }
 If LZWBitsInBuffer > 0 Then Begin
  LZWByteBuffer[LZWByteCount] := LZWBitBuffer And $FF;
  Inc(LZWByteCount);
 End;

 FlushLZWByteBuffer(F);

 { Ã‰crire le bloc terminateur (taille 0) }
 WriteByte(F, 0);
End;

{ Fonction pour chercher un code dans la table LZW }
Function FindLZWCode(Prefix: Integer; Suffix: Byte): Integer;
Var
 I: Integer;
Begin
 FindLZWCode := -1;
 For I := LZWEOICode + 1 to LZWNextCode - 1 do Begin
  If (LZWTable[I].Prefix = Prefix) And (LZWTable[I].Suffix = Suffix) Then Begin
   FindLZWCode := I;
   Exit;
  End;
 End;
End;

{ Fonction pour ajouter un code Ã  la table LZW }
Function AddLZWCode(Prefix: Integer; Suffix: Byte): Integer;
Begin
 If LZWNextCode < 4096 Then Begin
  LZWTable[LZWNextCode].Prefix := Prefix;
  LZWTable[LZWNextCode].Suffix := Suffix;
  AddLZWCode := LZWNextCode;
  Inc(LZWNextCode);

  { Augmenter la taille du code si nÃ©cessaire }
  If (LZWNextCode > (1 Shl LZWCodeSize)) And (LZWCodeSize < GIF_MAX_CODE_SIZE) Then
   Inc(LZWCodeSize);
 End
 Else
  AddLZWCode := -1;
End;

{ ProcÃ©dure pour Ã©crire l'en-tÃªte GIF }
Procedure WriteGIFHeader(Var F: File; Width, Height: Integer; ColorBits: Integer);
Var
 PackedByte: Byte;
Begin
 { Signature et version "GIF89a" }
 BlockWrite(F, GIF_SIGNATURE[1], 3);
 BlockWrite(F, GIF_VERSION[1], 3);

 { Logical Screen Descriptor }
 WriteWord(F, Width);         { Largeur }
 WriteWord(F, Height);        { Hauteur }

 { Packed byte: Global Color Table Flag (1), Color Resolution (3), Sort Flag (1), Size of Global Color Table (3) }
 PackedByte := $80;                          { Global Color Table prÃ©sente }
 PackedByte := PackedByte Or ((ColorBits - 1) Shl 4);  { Color Resolution }
 PackedByte := PackedByte Or (ColorBits - 1);          { Size of Global Color Table }
 WriteByte(F, PackedByte);

 WriteByte(F, 0);             { Background Color Index }
 WriteByte(F, 0);             { Pixel Aspect Ratio }
End;

{ ProcÃ©dure pour Ã©crire la palette GIF (Global Color Table) }
Procedure WriteGIFPalette(Var F: File; TransparentIndex: Integer);
Var
 I: Integer;
 R, G, B: Byte;
Begin
 { Ã‰crire les 256 couleurs }
 For I := 0 to 255 do Begin
  If I < 16 Then Begin
   PaletteToRGB(I, R, G, B);
  End
  Else Begin
   { Niveaux de gris pour les couleurs 16-255 }
   R := (I - 16) + (I - 16) Div 15;
   G := R;
   B := R;
  End;

  WriteByte(F, R);
  WriteByte(F, G);
  WriteByte(F, B);
 End;
End;

{ ProcÃ©dure pour Ã©crire l'extension de contrÃ´le graphique (transparence) }
Procedure WriteGIFGCE(Var F: File; TransparentIndex: Integer; HasTransparency: Boolean);
Var
 PackedByte: Byte;
Begin
 WriteByte(F, GIF_EXTENSION);    { Extension Introducer }
 WriteByte(F, GIF_GCE_LABEL);    { Graphics Control Label }
 WriteByte(F, 4);                { Block Size (toujours 4) }

 { Packed byte: Reserved (3), Disposal Method (3), User Input (1), Transparent Color Flag (1) }
 If HasTransparency Then
  PackedByte := $01  { Transparent Color Flag = 1 }
 Else
  PackedByte := $00;
 WriteByte(F, PackedByte);

 WriteWord(F, 0);                { Delay Time (pas d'animation) }

 If HasTransparency Then
  WriteByte(F, TransparentIndex) { Transparent Color Index }
 Else
  WriteByte(F, 0);

 WriteByte(F, 0);                { Block Terminator }
End;

{ ProcÃ©dure pour Ã©crire le descripteur d'image }
Procedure WriteGIFImageDescriptor(Var F: File; Width, Height: Integer);
Begin
 WriteByte(F, GIF_IMAGE_SEPARATOR);  { Image Separator ',' }
 WriteWord(F, 0);                     { Left Position }
 WriteWord(F, 0);                     { Top Position }
 WriteWord(F, Width);                 { Image Width }
 WriteWord(F, Height);                { Image Height }
 WriteByte(F, 0);                     { Packed byte: pas de Local Color Table }
End;

{ ProcÃ©dure pour Ã©crire les donnÃ©es d'image compressÃ©es LZW }
Procedure WriteGIFImageData(Var F: File; Width, Height: Integer; ColorBits: Integer);
Var
 X, Y: Integer;
 Pixel: Byte;
 CurrentCode: Integer;
 NewCode: Integer;
Begin
 { LZW Minimum Code Size }
 WriteByte(F, ColorBits);

 { Initialiser la table LZW }
 InitLZWTable(ColorBits);

 { Ã‰crire le code Clear }
 WriteLZWCode(F, LZWClearCode);

 { Encoder les pixels }
 CurrentCode := -1;

 For Y := 0 to Height - 1 do Begin
  For X := 0 to Width - 1 do Begin
   Pixel := PixelBuffer^[Y, X];

   If CurrentCode = -1 Then
    CurrentCode := Pixel
   Else Begin
    NewCode := FindLZWCode(CurrentCode, Pixel);

    If NewCode >= 0 Then
     CurrentCode := NewCode
    Else Begin
     { Ã‰crire le code actuel }
     WriteLZWCode(F, CurrentCode);

     { Ajouter le nouveau code Ã  la table }
     If LZWNextCode < 4096 Then
      AddLZWCode(CurrentCode, Pixel)
     Else Begin
      { Table pleine, Ã©mettre un code Clear et rÃ©initialiser }
      WriteLZWCode(F, LZWClearCode);
      ResetLZWTable(ColorBits);
     End;

     CurrentCode := Pixel;
    End;
   End;
  End;
 End;

 { Ã‰crire le dernier code }
 If CurrentCode >= 0 Then
  WriteLZWCode(F, CurrentCode);

 { Ã‰crire le code End of Information }
 WriteLZWCode(F, LZWEOICode);

 { Terminer la sortie LZW }
 FinishLZWOutput(F);
End;

{ Fonction principale pour sauvegarder un fichier GIF }
{ TransparentIndex: index de la couleur transparente (-1 = pas de transparence) }
Function SaveGIFFile(Const FileName: String; TransparentIndex: Integer): Boolean;
Var
 F: File;
 Width, Height: Integer;
 HasTransparency: Boolean;
 ColorBits: Integer;
Begin
 SaveGIFFile := False;
 ColorBits := 8;
 HasTransparency := (TransparentIndex >= 0) And (TransparentIndex <= 255);

 If Not PrepareExportBuffer(Width, Height) Then Exit;

 { Ouvrir le fichier }
 Assign(F, FileName);
 {$I-}
 Rewrite(F, 1);
 {$I+}
 If IOResult <> 0 Then Begin
  FreePixelBuffer;
  Exit;
 End;

 { Ã‰crire l'en-tÃªte GIF }
 WriteGIFHeader(F, Width, Height, ColorBits);

 { Ã‰crire la palette globale }
 WriteGIFPalette(F, TransparentIndex);

 { Ã‰crire l'extension de contrÃ´le graphique (pour transparence) }
 WriteGIFGCE(F, TransparentIndex, HasTransparency);

 { Ã‰crire le descripteur d'image }
 WriteGIFImageDescriptor(F, Width, Height);

 { Ã‰crire les donnÃ©es d'image compressÃ©es }
 WriteGIFImageData(F, Width, Height, ColorBits);

 { Ã‰crire le terminateur GIF }
 WriteByte(F, GIF_TRAILER);

 Close(F);
 FreePixelBuffer;
 SaveGIFFile := True;
End;

{ ============================================================================ }
{ === FIN DES FONCTIONS D'EXPORT GIF === }
{ ============================================================================ }

{ ============================================================================ }
{ === FONCTIONS D'EXPORT JPEG (TODO 25) === }
{ ============================================================================ }

{ Constantes pour le format JPEG }
Const
 JPEG_SOI = $FFD8;           { Start of Image }
 JPEG_EOI = $FFD9;           { End of Image }
 JPEG_APP0 = $FFE0;          { JFIF marker }
 JPEG_DQT = $FFDB;           { Define Quantization Table }
 JPEG_SOF0 = $FFC0;          { Start of Frame (Baseline DCT) }
 JPEG_DHT = $FFC4;           { Define Huffman Table }
 JPEG_SOS = $FFDA;           { Start of Scan }
 JPEG_BLOCK_SIZE = 8;        { Taille d'un bloc DCT }

{ Tables de quantisation JPEG standard (qualitÃ© 50) }
Const
 JPEG_QT_LUMA: Array[0..63] of Byte = (
  16, 11, 10, 16,  24,  40,  51,  61,
  12, 12, 14, 19,  26,  58,  60,  55,
  14, 13, 16, 24,  40,  57,  69,  56,
  14, 17, 22, 29,  51,  87,  80,  62,
  18, 22, 37, 56,  68, 109, 103,  77,
  24, 35, 55, 64,  81, 104, 113,  92,
  49, 64, 78, 87, 103, 121, 120, 101,
  72, 92, 95, 98, 112, 100, 103,  99
 );

 JPEG_QT_CHROMA: Array[0..63] of Byte = (
  17, 18, 24, 47, 99, 99, 99, 99,
  18, 21, 26, 66, 99, 99, 99, 99,
  24, 26, 56, 99, 99, 99, 99, 99,
  47, 66, 99, 99, 99, 99, 99, 99,
  99, 99, 99, 99, 99, 99, 99, 99,
  99, 99, 99, 99, 99, 99, 99, 99,
  99, 99, 99, 99, 99, 99, 99, 99,
  99, 99, 99, 99, 99, 99, 99, 99
 );

{ Ordre zig-zag pour les coefficients DCT }
Const
 JPEG_ZIGZAG: Array[0..63] of Byte = (
   0,  1,  8, 16,  9,  2,  3, 10,
  17, 24, 32, 25, 18, 11,  4,  5,
  12, 19, 26, 33, 40, 48, 41, 34,
  27, 20, 13,  6,  7, 14, 21, 28,
  35, 42, 49, 56, 57, 50, 43, 36,
  29, 22, 15, 23, 30, 37, 44, 51,
  58, 59, 52, 45, 38, 31, 39, 46,
  53, 60, 61, 54, 47, 55, 62, 63
 );

{ Tables de Huffman DC/AC standard }
Const
 JPEG_DC_BITS: Array[0..15] of Byte = (0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0);
 JPEG_DC_VALS: Array[0..11] of Byte = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
 JPEG_AC_BITS: Array[0..15] of Byte = (0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 125);
 JPEG_AC_VALS: Array[0..161] of Byte = (
  $01, $02, $03, $00, $04, $11, $05, $12, $21, $31, $41, $06, $13, $51, $61, $07,
  $22, $71, $14, $32, $81, $91, $A1, $08, $23, $42, $B1, $C1, $15, $52, $D1, $F0,
  $24, $33, $62, $72, $82, $09, $0A, $16, $17, $18, $19, $1A, $25, $26, $27, $28,
  $29, $2A, $34, $35, $36, $37, $38, $39, $3A, $43, $44, $45, $46, $47, $48, $49,
  $4A, $53, $54, $55, $56, $57, $58, $59, $5A, $63, $64, $65, $66, $67, $68, $69,
  $6A, $73, $74, $75, $76, $77, $78, $79, $7A, $83, $84, $85, $86, $87, $88, $89,
  $8A, $92, $93, $94, $95, $96, $97, $98, $99, $9A, $A2, $A3, $A4, $A5, $A6, $A7,
  $A8, $A9, $AA, $B2, $B3, $B4, $B5, $B6, $B7, $B8, $B9, $BA, $C2, $C3, $C4, $C5,
  $C6, $C7, $C8, $C9, $CA, $D2, $D3, $D4, $D5, $D6, $D7, $D8, $D9, $DA, $E1, $E2,
  $E3, $E4, $E5, $E6, $E7, $E8, $E9, $EA, $F1, $F2, $F3, $F4, $F5, $F6, $F7, $F8,
  $F9, $FA
 );

Type
 TJPEGBlock = Array[0..63] of Integer;
 TJPEGQuantTable = Array[0..63] of Integer;

Var
 JPEGQuality: Integer;
 JPEGQuantLuma: TJPEGQuantTable;
 JPEGQuantChroma: TJPEGQuantTable;
 JPEGBitBuffer: LongInt;
 JPEGBitsInBuffer: Integer;
 JPEGPrevDC_Y: Integer;
 JPEGPrevDC_Cb: Integer;
 JPEGPrevDC_Cr: Integer;

{ Initialiser les tables de quantisation selon la qualitÃ© }
Procedure InitJPEGQuantTables(Quality: Integer);
Var
 I: Integer;
 Scale: Integer;
 Temp: Integer;
Begin
 If Quality < 1 Then Quality := 1;
 If Quality > 100 Then Quality := 100;

 { Calculer le facteur d'Ã©chelle }
 If Quality < 50 Then
  Scale := 5000 Div Quality
 Else
  Scale := 200 - Quality * 2;

 { GÃ©nÃ©rer les tables de quantisation }
 For I := 0 to 63 do Begin
  { Table Luminance }
  Temp := (JPEG_QT_LUMA[I] * Scale + 50) Div 100;
  If Temp < 1 Then Temp := 1;
  If Temp > 255 Then Temp := 255;
  JPEGQuantLuma[I] := Temp;

  { Table Chrominance }
  Temp := (JPEG_QT_CHROMA[I] * Scale + 50) Div 100;
  If Temp < 1 Then Temp := 1;
  If Temp > 255 Then Temp := 255;
  JPEGQuantChroma[I] := Temp;
 End;
End;

{ Ã‰crire un marqueur JPEG (2 octets) }
Procedure WriteJPEGMarker(Var F: File; Marker: Word);
Var
 B: Byte;
Begin
 B := Hi(Marker);
 BlockWrite(F, B, 1);
 B := Lo(Marker);
 BlockWrite(F, B, 1);
End;

{ Ã‰crire l'en-tÃªte JFIF APP0 }
Procedure WriteJPEGAPP0(Var F: File);
Var
 B: Byte;
 Len: Word;
Begin
 WriteJPEGMarker(F, JPEG_APP0);

 { Longueur du segment (16 octets) }
 B := 0; BlockWrite(F, B, 1);
 B := 16; BlockWrite(F, B, 1);

 { Identificateur "JFIF\0" }
 B := Ord('J'); BlockWrite(F, B, 1);
 B := Ord('F'); BlockWrite(F, B, 1);
 B := Ord('I'); BlockWrite(F, B, 1);
 B := Ord('F'); BlockWrite(F, B, 1);
 B := 0; BlockWrite(F, B, 1);

 { Version JFIF 1.01 }
 B := 1; BlockWrite(F, B, 1);
 B := 1; BlockWrite(F, B, 1);

 { UnitÃ©s (0 = pas d'unitÃ©) }
 B := 0; BlockWrite(F, B, 1);

 { DensitÃ© X et Y (1x1) }
 B := 0; BlockWrite(F, B, 1);
 B := 1; BlockWrite(F, B, 1);
 B := 0; BlockWrite(F, B, 1);
 B := 1; BlockWrite(F, B, 1);

 { Pas de vignette }
 B := 0; BlockWrite(F, B, 1);
 B := 0; BlockWrite(F, B, 1);
End;

{ Ã‰crire une table de quantisation DQT }
Procedure WriteJPEGDQT(Var F: File; TableID: Integer; Const QTable: TJPEGQuantTable);
Var
 B: Byte;
 I: Integer;
Begin
 WriteJPEGMarker(F, JPEG_DQT);

 { Longueur (2 + 1 + 64 = 67) }
 B := 0; BlockWrite(F, B, 1);
 B := 67; BlockWrite(F, B, 1);

 { ID de la table (4 bits precision + 4 bits ID) }
 B := TableID; BlockWrite(F, B, 1);

 { 64 coefficients en ordre zig-zag }
 For I := 0 to 63 do Begin
  B := QTable[JPEG_ZIGZAG[I]];
  BlockWrite(F, B, 1);
 End;
End;

{ Ã‰crire le marqueur SOF0 (Start of Frame) }
Procedure WriteJPEGSOF0(Var F: File; Width, Height: Integer);
Var
 B: Byte;
Begin
 WriteJPEGMarker(F, JPEG_SOF0);

 { Longueur (2 + 1 + 2 + 2 + 1 + 3*3 = 17) }
 B := 0; BlockWrite(F, B, 1);
 B := 17; BlockWrite(F, B, 1);

 { PrÃ©cision (8 bits) }
 B := 8; BlockWrite(F, B, 1);

 { Hauteur }
 B := Hi(Height); BlockWrite(F, B, 1);
 B := Lo(Height); BlockWrite(F, B, 1);

 { Largeur }
 B := Hi(Width); BlockWrite(F, B, 1);
 B := Lo(Width); BlockWrite(F, B, 1);

 { Nombre de composants (3 = YCbCr) }
 B := 3; BlockWrite(F, B, 1);

 { Composant Y (ID=1, sampling 1x1, table quant 0) }
 B := 1; BlockWrite(F, B, 1);
 B := $11; BlockWrite(F, B, 1);  { 1x1 }
 B := 0; BlockWrite(F, B, 1);

 { Composant Cb (ID=2, sampling 1x1, table quant 1) }
 B := 2; BlockWrite(F, B, 1);
 B := $11; BlockWrite(F, B, 1);
 B := 1; BlockWrite(F, B, 1);

 { Composant Cr (ID=3, sampling 1x1, table quant 1) }
 B := 3; BlockWrite(F, B, 1);
 B := $11; BlockWrite(F, B, 1);
 B := 1; BlockWrite(F, B, 1);
End;

{ Ã‰crire une table de Huffman DHT }
Procedure WriteJPEGDHT(Var F: File; TableClass, TableID: Integer;
                       Const Bits: Array of Byte; Const Vals: Array of Byte;
                       NumVals: Integer);
Var
 B: Byte;
 I: Integer;
 Len: Integer;
Begin
 WriteJPEGMarker(F, JPEG_DHT);

 { Calculer la longueur }
 Len := 2 + 1 + 16 + NumVals;
 B := Hi(Len); BlockWrite(F, B, 1);
 B := Lo(Len); BlockWrite(F, B, 1);

 { Classe et ID de la table }
 B := (TableClass Shl 4) Or TableID;
 BlockWrite(F, B, 1);

 { 16 octets de compteurs de bits }
 For I := 0 to 15 do Begin
  B := Bits[I];
  BlockWrite(F, B, 1);
 End;

 { Valeurs des symboles }
 For I := 0 to NumVals - 1 do Begin
  B := Vals[I];
  BlockWrite(F, B, 1);
 End;
End;

{ Ã‰crire le marqueur SOS (Start of Scan) }
Procedure WriteJPEGSOS(Var F: File);
Var
 B: Byte;
Begin
 WriteJPEGMarker(F, JPEG_SOS);

 { Longueur (2 + 1 + 3*2 + 3 = 12) }
 B := 0; BlockWrite(F, B, 1);
 B := 12; BlockWrite(F, B, 1);

 { Nombre de composants }
 B := 3; BlockWrite(F, B, 1);

 { Y: table DC 0, table AC 0 }
 B := 1; BlockWrite(F, B, 1);
 B := $00; BlockWrite(F, B, 1);

 { Cb: table DC 1, table AC 1 }
 B := 2; BlockWrite(F, B, 1);
 B := $11; BlockWrite(F, B, 1);

 { Cr: table DC 1, table AC 1 }
 B := 3; BlockWrite(F, B, 1);
 B := $11; BlockWrite(F, B, 1);

 { Spectral selection }
 B := 0; BlockWrite(F, B, 1);   { Ss }
 B := 63; BlockWrite(F, B, 1);  { Se }
 B := 0; BlockWrite(F, B, 1);   { Ah/Al }
End;

{ Convertir RGB en YCbCr }
Procedure RGBToYCbCr(R, G, B: Byte; Var Y, Cb, Cr: Integer);
Begin
 Y  := Round(0.299 * R + 0.587 * G + 0.114 * B);
 Cb := Round(-0.169 * R - 0.331 * G + 0.500 * B + 128);
 Cr := Round(0.500 * R - 0.419 * G - 0.081 * B + 128);

 If Y < 0 Then Y := 0; If Y > 255 Then Y := 255;
 If Cb < 0 Then Cb := 0; If Cb > 255 Then Cb := 255;
 If Cr < 0 Then Cr := 0; If Cr > 255 Then Cr := 255;
End;

{ Ã‰crire un octet compressÃ© JPEG (avec byte stuffing) }
Procedure WriteJPEGByte(Var F: File; B: Byte);
Var
 Stuff: Byte;
Begin
 BlockWrite(F, B, 1);
 If B = $FF Then Begin
  Stuff := $00;
  BlockWrite(F, Stuff, 1);
 End;
End;

{ Vider le buffer de bits JPEG }
Procedure FlushJPEGBits(Var F: File);
Var
 B: Byte;
Begin
 If JPEGBitsInBuffer > 0 Then Begin
  { ComplÃ©ter avec des 1 }
  While JPEGBitsInBuffer < 8 do Begin
   JPEGBitBuffer := (JPEGBitBuffer Shl 1) Or 1;
   Inc(JPEGBitsInBuffer);
  End;
  B := JPEGBitBuffer And $FF;
  WriteJPEGByte(F, B);
  JPEGBitBuffer := 0;
  JPEGBitsInBuffer := 0;
 End;
End;

{ Ã‰crire des bits dans le buffer JPEG }
Procedure WriteJPEGBits(Var F: File; Value: LongInt; NumBits: Integer);
Var
 B: Byte;
Begin
 While NumBits > 0 do Begin
  JPEGBitBuffer := (JPEGBitBuffer Shl 1) Or ((Value Shr (NumBits - 1)) And 1);
  Inc(JPEGBitsInBuffer);
  Dec(NumBits);

  If JPEGBitsInBuffer = 8 Then Begin
   B := JPEGBitBuffer And $FF;
   WriteJPEGByte(F, B);
   JPEGBitBuffer := 0;
   JPEGBitsInBuffer := 0;
  End;
 End;
End;

{ Encoder les donnÃ©es d'image JPEG (encodeur baseline complet) }

Type
 TJPEGRealBlock = Array[0..63] of Real;
 TJPEGSymCode   = Array[0..255] of Word;
 TJPEGSymSize   = Array[0..255] of Byte;

Var
 JPEG_CosTab: Array[0..7, 0..7] of Real;
 JPEG_DCCode, JPEG_ACCode: TJPEGSymCode;
 JPEG_DCSize, JPEG_ACSize: TJPEGSymSize;

Procedure InitJPEGCosTab;
Var I, J: Integer;
Begin
 For I := 0 To 7 Do
  For J := 0 To 7 Do
   JPEG_CosTab[I, J] := Cos((2*I + 1) * J * Pi / 16);
End;

Procedure BuildJPEGHuffTable(Const Counts: Array of Byte;
                             Const Values: Array of Byte;
                             NumValues: Integer;
                             Var Codes: TJPEGSymCode;
                             Var Sizes: TJPEGSymSize);
Var
 I, J, K: Integer;
 Code: Word;
 Size: Integer;
 HuffSize: Array[0..256] of Byte;
 HuffCode: Array[0..256] of Word;
Begin
 K := 0;
 For I := 1 To 16 Do
  For J := 1 To Counts[I-1] Do Begin
   HuffSize[K] := Byte(I);
   Inc(K);
  End;
 HuffSize[K] := 0;
 Code := 0;
 Size := HuffSize[0];
 K := 0;
 While HuffSize[K] <> 0 Do Begin
  While (HuffSize[K] <> 0) And (Integer(HuffSize[K]) = Size) Do Begin
   HuffCode[K] := Code;
   Inc(Code);
   Inc(K);
  End;
  If HuffSize[K] = 0 Then Break;
  Repeat
   Code := Word(Code Shl 1);
   Inc(Size);
  Until Integer(HuffSize[K]) = Size;
 End;
 For I := 0 To 255 Do Begin Codes[I] := 0; Sizes[I] := 0; End;
 For I := 0 To NumValues - 1 Do Begin
  Codes[Values[I]] := HuffCode[I];
  Sizes[Values[I]] := HuffSize[I];
 End;
End;

Procedure InitJPEGHuffTables;
Begin
 BuildJPEGHuffTable(JPEG_DC_BITS, JPEG_DC_VALS, 12,
                    JPEG_DCCode, JPEG_DCSize);
 BuildJPEGHuffTable(JPEG_AC_BITS, JPEG_AC_VALS, 162,
                    JPEG_ACCode, JPEG_ACSize);
End;

Procedure JPEGForwardDCT(Var Blk: TJPEGRealBlock);
Const OneOverSqrt2 = 0.70710678118654752;
Var
 U, V, X, Y: Integer;
 Sum, Cu, Cv: Real;
 Tmp: TJPEGRealBlock;
Begin
 For V := 0 To 7 Do Begin
  If V = 0 Then Cv := OneOverSqrt2 Else Cv := 1.0;
  For U := 0 To 7 Do Begin
   If U = 0 Then Cu := OneOverSqrt2 Else Cu := 1.0;
   Sum := 0.0;
   For Y := 0 To 7 Do
    For X := 0 To 7 Do
     Sum := Sum + Blk[Y*8+X] * JPEG_CosTab[X, U] * JPEG_CosTab[Y, V];
   Tmp[V*8+U] := 0.25 * Cu * Cv * Sum;
  End;
 End;
 For U := 0 To 63 Do Blk[U] := Tmp[U];
End;

Procedure JPEGQuantizeZigzag(Const Src: TJPEGRealBlock;
                             Const QT: TJPEGQuantTable;
                             Var Dst: TJPEGBlock);
Var I, Q: Integer; V: Real;
Begin
 For I := 0 To 63 Do Begin
  V := Src[JPEG_ZIGZAG[I]];
  Q := QT[JPEG_ZIGZAG[I]];
  If Q < 1 Then Q := 1;
  If V >= 0 Then Dst[I] := Trunc((V + Q/2) / Q)
            Else Dst[I] := -Trunc((-V + Q/2) / Q);
 End;
End;

Procedure JPEGEncodeCoef(Value: Integer; Var Size: Integer; Var Bits: Word);
Var AV: LongInt;
Begin
 AV := Abs(Value);
 Size := 0;
 While AV <> 0 Do Begin Inc(Size); AV := AV Shr 1; End;
 If Value < 0 Then
  Bits := Word((LongInt(Value) + (LongInt(1) Shl Size) - 1)
               And ((LongInt(1) Shl Size) - 1))
 Else
  Bits := Word(Value);
End;

Procedure JPEGEncodeBlock(Var F: File; Const ZZ: TJPEGBlock; Var PrevDC: Integer);
Var K, RunLen, Size, RS: Integer; Diff: Integer; Bits: Word;
Begin
 { Coefficient DC : codage diffÃ©rentiel }
 Diff := ZZ[0] - PrevDC;
 PrevDC := ZZ[0];
 JPEGEncodeCoef(Diff, Size, Bits);
 WriteJPEGBits(F, JPEG_DCCode[Size], JPEG_DCSize[Size]);
 If Size > 0 Then WriteJPEGBits(F, Bits, Size);
 { Coefficients AC }
 K := 1;
 While K <= 63 Do Begin
  RunLen := 0;
  While (K <= 63) And (ZZ[K] = 0) Do Begin Inc(K); Inc(RunLen); End;
  If K > 63 Then Begin
   WriteJPEGBits(F, JPEG_ACCode[$00], JPEG_ACSize[$00]); { EOB }
   Break;
  End;
  While RunLen >= 16 Do Begin
   WriteJPEGBits(F, JPEG_ACCode[$F0], JPEG_ACSize[$F0]); { ZRL }
   Dec(RunLen, 16);
  End;
  JPEGEncodeCoef(ZZ[K], Size, Bits);
  RS := (RunLen Shl 4) Or Size;
  WriteJPEGBits(F, JPEG_ACCode[RS], JPEG_ACSize[RS]);
  If Size > 0 Then WriteJPEGBits(F, Bits, Size);
  Inc(K);
 End;
End;

Procedure WriteJPEGImageData(Var F: File; Width, Height: Integer);
Var
 X, Y, BX, BY, I, J: Integer;
 R, G, B: Byte;
 YV, CbV, CrV: Integer;
 BlkY, BlkCb, BlkCr: TJPEGRealBlock;
 ZZ: TJPEGBlock;
Begin
 InitJPEGCosTab;
 InitJPEGHuffTables;
 JPEGBitBuffer := 0;
 JPEGBitsInBuffer := 0;
 JPEGPrevDC_Y := 0;
 JPEGPrevDC_Cb := 0;
 JPEGPrevDC_Cr := 0;

 BY := 0;
 While BY < Height Do Begin
  BX := 0;
  While BX < Width Do Begin
   For J := 0 To 7 Do Begin
    For I := 0 To 7 Do Begin
     X := BX + I;
     Y := BY + J;
     If X >= Width Then X := Width - 1;
     If Y >= Height Then Y := Height - 1;
     If (X < BufferWidth) And (Y < BufferHeight) Then Begin
      PaletteToRGB(PixelBuffer^[Y, X], R, G, B);
      RGBToYCbCr(R, G, B, YV, CbV, CrV);
     End Else Begin
      YV := 128; CbV := 128; CrV := 128;
     End;
     BlkY [J*8+I] := YV  - 128;
     BlkCb[J*8+I] := CbV - 128;
     BlkCr[J*8+I] := CrV - 128;
    End;
   End;
   JPEGForwardDCT(BlkY);
   JPEGQuantizeZigzag(BlkY, JPEGQuantLuma, ZZ);
   JPEGEncodeBlock(F, ZZ, JPEGPrevDC_Y);
   JPEGForwardDCT(BlkCb);
   JPEGQuantizeZigzag(BlkCb, JPEGQuantChroma, ZZ);
   JPEGEncodeBlock(F, ZZ, JPEGPrevDC_Cb);
   JPEGForwardDCT(BlkCr);
   JPEGQuantizeZigzag(BlkCr, JPEGQuantChroma, ZZ);
   JPEGEncodeBlock(F, ZZ, JPEGPrevDC_Cr);
   Inc(BX, 8);
  End;
  Inc(BY, 8);
 End;

 FlushJPEGBits(F);
End;

{ Fonction principale pour sauvegarder un fichier JPEG }
{ Quality: niveau de qualitÃ© de 1 (pire) Ã  100 (meilleur) }

{ Fonction principale pour sauvegarder un fichier JPEG }
{ Quality: niveau de qualitÃ© de 1 (pire) Ã  100 (meilleur) }

{ Calculer la boÃ®te englobante de toutes les formes.
  Retourne False si aucune forme n'est dÃ©finie. }
Function CalculateDrawingBounds(Var MinX, MinY, MaxX, MaxY: Integer): Boolean;
Var
 I: Integer;
Begin
 CalculateDrawingBounds := False;
 If ShapeCount <= 0 Then Exit;

 MinX := 32767; MinY := 32767;
 MaxX := -32768; MaxY := -32768;

 For I := 1 to ShapeCount do Begin
  If Shapes[I].X1 < MinX Then MinX := Shapes[I].X1;
  If Shapes[I].Y1 < MinY Then MinY := Shapes[I].Y1;
  If Shapes[I].X2 < MinX Then MinX := Shapes[I].X2;
  If Shapes[I].Y2 < MinY Then MinY := Shapes[I].Y2;
  If Shapes[I].X1 > MaxX Then MaxX := Shapes[I].X1;
  If Shapes[I].Y1 > MaxY Then MaxY := Shapes[I].Y1;
  If Shapes[I].X2 > MaxX Then MaxX := Shapes[I].X2;
  If Shapes[I].Y2 > MaxY Then MaxY := Shapes[I].Y2;
 End;
 CalculateDrawingBounds := True;
End;

{ DÃ©caler temporairement toutes les formes (pour rendu dans un buffer
  d'export). Appeler avec (-OffsetX, -OffsetY) pour restaurer. }
Procedure AdjustShapesForBuffer(OffsetX, OffsetY: Integer);
Var
 I: Integer;
Begin
 For I := 1 to ShapeCount do Begin
  Shapes[I].X1 := Shapes[I].X1 - OffsetX;
  Shapes[I].Y1 := Shapes[I].Y1 - OffsetY;
  Shapes[I].X2 := Shapes[I].X2 - OffsetX;
  Shapes[I].Y2 := Shapes[I].Y2 - OffsetY;
 End;
End;

Function SaveJPEGFile(Const FileName: String; Quality: Integer): Boolean;
Var
 F: File;
 Width, Height: Integer;
Begin
 SaveJPEGFile := False;
 JPEGQuality := Quality;
 If JPEGQuality < 1 Then JPEGQuality := 1;
 If JPEGQuality > 100 Then JPEGQuality := 100;

 If Not PrepareExportBuffer(Width, Height) Then Exit;

 { Initialiser les tables de quantisation }
 InitJPEGQuantTables(JPEGQuality);

 { CrÃ©er le fichier }
 Assign(F, FileName);
 {$I-}
 Rewrite(F, 1);
 {$I+}
 If IOResult <> 0 Then Begin
  FreePixelBuffer;
  Exit;
 End;

 { Ã‰crire le marqueur SOI (Start of Image) }
 WriteJPEGMarker(F, JPEG_SOI);

 { Ã‰crire le segment JFIF APP0 }
 WriteJPEGAPP0(F);

 { Ã‰crire les tables de quantisation }
 WriteJPEGDQT(F, 0, JPEGQuantLuma);
 WriteJPEGDQT(F, 1, JPEGQuantChroma);

 { Ã‰crire le marqueur SOF0 }
 WriteJPEGSOF0(F, Width, Height);

 { Ã‰crire les tables de Huffman }
 WriteJPEGDHT(F, 0, 0, JPEG_DC_BITS, JPEG_DC_VALS, 12);  { DC Luma }
 WriteJPEGDHT(F, 0, 1, JPEG_DC_BITS, JPEG_DC_VALS, 12);  { DC Chroma }
 WriteJPEGDHT(F, 1, 0, JPEG_AC_BITS, JPEG_AC_VALS, 162); { AC Luma }
 WriteJPEGDHT(F, 1, 1, JPEG_AC_BITS, JPEG_AC_VALS, 162); { AC Chroma }

 { Ã‰crire le marqueur SOS }
 WriteJPEGSOS(F);

 { Ã‰crire les donnÃ©es d'image compressÃ©es }
 WriteJPEGImageData(F, Width, Height);

 { Ã‰crire le marqueur EOI (End of Image) }
 WriteJPEGMarker(F, JPEG_EOI);

 Close(F);
 FreePixelBuffer;
 SaveJPEGFile := True;
End;

{ ============================================================================ }
{ === FIN DES FONCTIONS D'EXPORT JPEG === }
{ ============================================================================ }

{ ============================================================================ }
{ === FONCTIONS D'EXPORT PNG (TODO 25) === }
{ ============================================================================ }

{ Constantes pour le format PNG }
Const
 PNG_SIGNATURE: Array[0..7] of Byte = ($89, $50, $4E, $47, $0D, $0A, $1A, $0A);
 PNG_CHUNK_IHDR = $49484452;  { 'IHDR' }
 PNG_CHUNK_IDAT = $49444154;  { 'IDAT' }
 PNG_CHUNK_IEND = $49454E44;  { 'IEND' }
 PNG_CHUNK_PLTE = $504C5445;  { 'PLTE' }
 PNG_CHUNK_tRNS = $74524E53;  { 'tRNS' }

 PNG_COLOR_GRAYSCALE = 0;
 PNG_COLOR_RGB = 2;
 PNG_COLOR_INDEXED = 3;
 PNG_COLOR_GRAYSCALE_ALPHA = 4;
 PNG_COLOR_RGBA = 6;

{ Table CRC32 pour PNG }
Var
 PNG_CRC_Table: Array[0..255] of LongInt;
 PNG_CRC_Initialized: Boolean;

{ Initialiser la table CRC32 }
Procedure InitPNGCRCTable;
Var
 C: LongInt;
 N, K: Integer;
Begin
 If PNG_CRC_Initialized Then Exit;

 For N := 0 to 255 do Begin
  C := LongInt(N);
  For K := 0 to 7 do Begin
   If (C And 1) <> 0 Then
    C := LongInt($EDB88320) Xor (C Shr 1)
   Else
    C := C Shr 1;
  End;
  PNG_CRC_Table[N] := C;
 End;
 PNG_CRC_Initialized := True;
End;

{ Calculer le CRC32 }
Function UpdateCRC(CRC: LongInt; Const Data: Array of Byte; Len: Integer): LongInt;
Var
 I: Integer;
Begin
 For I := 0 to Len - 1 do
  CRC := PNG_CRC_Table[(CRC Xor Data[I]) And $FF] Xor (CRC Shr 8);
 UpdateCRC := CRC;
End;

{ Ã‰crire un entier 32-bit big-endian }
Procedure WritePNGInt32(Var F: File; Value: LongInt);
Var
 B: Array[0..3] of Byte;
Begin
 B[0] := (Value Shr 24) And $FF;
 B[1] := (Value Shr 16) And $FF;
 B[2] := (Value Shr 8) And $FF;
 B[3] := Value And $FF;
 BlockWrite(F, B, 4);
End;

{ Ã‰crire la signature PNG }
Procedure WritePNGSignature(Var F: File);
Begin
 BlockWrite(F, PNG_SIGNATURE, 8);
End;

{ Ã‰crire un chunk PNG }
Procedure WritePNGChunk(Var F: File; ChunkType: LongInt; Const Data: Array of Byte; DataLen: Integer);
Var
 TypeBytes: Array[0..3] of Byte;
 CRC: LongInt;
 I: Integer;
Begin
 { Ã‰crire la longueur }
 WritePNGInt32(F, DataLen);

 { Convertir le type en bytes }
 TypeBytes[0] := (ChunkType Shr 24) And $FF;
 TypeBytes[1] := (ChunkType Shr 16) And $FF;
 TypeBytes[2] := (ChunkType Shr 8) And $FF;
 TypeBytes[3] := ChunkType And $FF;

 { Ã‰crire le type }
 BlockWrite(F, TypeBytes, 4);

 { Ã‰crire les donnÃ©es }
 If DataLen > 0 Then
  BlockWrite(F, Data, DataLen);

 { Calculer et Ã©crire le CRC }
 { Note: CRC32 per PNG spec - initialized to $FFFFFFFF, then XOR'd at the end }
 CRC := $FFFFFFFF;
 CRC := UpdateCRC(CRC, TypeBytes, 4);
 If DataLen > 0 Then
  CRC := UpdateCRC(CRC, Data, DataLen);
 CRC := CRC Xor $FFFFFFFF;
 WritePNGInt32(F, CRC);
End;

{ Ã‰crire le chunk IHDR }
Procedure WritePNGIHDR(Var F: File; Width, Height: Integer; ColorType, BitDepth: Byte);
Var
 Data: Array[0..12] of Byte;
Begin
 { Width (4 bytes) }
 Data[0] := (Width Shr 24) And $FF;
 Data[1] := (Width Shr 16) And $FF;
 Data[2] := (Width Shr 8) And $FF;
 Data[3] := Width And $FF;

 { Height (4 bytes) }
 Data[4] := (Height Shr 24) And $FF;
 Data[5] := (Height Shr 16) And $FF;
 Data[6] := (Height Shr 8) And $FF;
 Data[7] := Height And $FF;

 { Bit depth }
 Data[8] := BitDepth;

 { Color type }
 Data[9] := ColorType;

 { Compression method (always 0) }
 Data[10] := 0;

 { Filter method (always 0) }
 Data[11] := 0;

 { Interlace method (0 = no interlace) }
 Data[12] := 0;

 WritePNGChunk(F, PNG_CHUNK_IHDR, Data, 13);
End;

{ ============================================================================ }
{ Streaming PNG IDAT writer.                                                   }
{                                                                              }
{ Plutot que de bufferiser toute l'image puis de l'ecrire en un seul chunk     }
{ (ce qui plafonne a ~32 KB en -Mtp a cause de Integer 16-bit signe et         }
{ produit des PNG tronques pour les images depassant ~128x128 en RGBA), on     }
{ ecrit le chunk IDAT en streaming :                                           }
{   - taille IDAT calculee a l'avance (zlib header + N blocs stored + adler)   }
{   - octets ecrits directement dans le fichier au fur et a mesure             }
{   - blocs deflate BTYPE=00 (stored) de 65535 octets maximum                  }
{   - CRC-32 du chunk et Adler-32 du flux zlib mis a jour incrementalement     }
{                                                                              }
{ Pattern inspire de BMP2PNG.PAS de ce meme projet.                             }
{ ============================================================================ }

Const
 PNG_MaxStoredBlock = 65535;

Var
 PNG_IDATCRC:         LongInt;
 PNG_IDATRemaining:   LongInt;
 PNG_IDATBlockRemain: LongInt;
 PNG_Adler_A:         LongInt;
 PNG_Adler_B:         LongInt;
 PNG_DestFile:        ^File;

Procedure PNG_WriteRawByte(B: Byte);
Var
 Buf: Array[0..0] of Byte;
 Wr: Word;
Begin
 Buf[0] := B;
 BlockWrite(PNG_DestFile^, Buf, 1, Wr);
End;

Procedure PNG_WriteRawBE32(Value: LongInt);
Var
 Buf: Array[0..3] of Byte;
 Wr: Word;
Begin
 Buf[0] := Byte((Value Shr 24) And $FF);
 Buf[1] := Byte((Value Shr 16) And $FF);
 Buf[2] := Byte((Value Shr 8)  And $FF);
 Buf[3] := Byte( Value         And $FF);
 BlockWrite(PNG_DestFile^, Buf, 4, Wr);
End;

{ Met a jour le CRC du chunk IDAT pour un octet. }
Procedure PNG_IDATCRCByte(B: Byte);
Begin
 PNG_IDATCRC := PNG_CRC_Table[(PNG_IDATCRC Xor LongInt(B)) And $FF] Xor (PNG_IDATCRC Shr 8);
End;

{ Ecrit un octet brut dans le fichier ET met a jour le CRC IDAT. }
Procedure PNG_IDATByte(B: Byte);
Begin
 PNG_WriteRawByte(B);
 PNG_IDATCRCByte(B);
End;

{ Ecrit l'en-tete d'un bloc deflate stored : 1 octet flags + 2 LEN + 2 NLEN. }
Procedure PNG_WriteStoredHeader(BlockLen: LongInt; IsLast: Byte);
Begin
 PNG_IDATByte(IsLast);
 PNG_IDATByte(Byte( BlockLen        And $FF));
 PNG_IDATByte(Byte((BlockLen Shr 8) And $FF));
 PNG_IDATByte(Byte((Not BlockLen)        And $FF));
 PNG_IDATByte(Byte((Not BlockLen) Shr 8  And $FF));
End;

{ Adler-32 (RFC 1950) incremental. }
Procedure PNG_UpdateAdler(B: Byte);
Begin
 PNG_Adler_A := (PNG_Adler_A + LongInt(B)) Mod 65521;
 PNG_Adler_B := (PNG_Adler_B + PNG_Adler_A) Mod 65521;
End;

{ Initialise l'ecriture du chunk IDAT pour TotalRaw octets de donnees zlib. }
Procedure PNG_BeginIDAT(TotalRaw: LongInt);
Var
 NumBlocks, IDATLen: LongInt;
 TypeBuf: Array[0..3] of Byte;
 Wr: Word;
Begin
 If TotalRaw <= 0 Then NumBlocks := 1
                  Else NumBlocks := (TotalRaw + PNG_MaxStoredBlock - 1) Div PNG_MaxStoredBlock;
 { Longueur du chunk IDAT = zlib hdr (2) + (5 + data) * NumBlocks + Adler (4). }
 IDATLen := 2 + TotalRaw + NumBlocks * 5 + 4;

 PNG_WriteRawBE32(IDATLen);

 TypeBuf[0] := Ord('I');
 TypeBuf[1] := Ord('D');
 TypeBuf[2] := Ord('A');
 TypeBuf[3] := Ord('T');
 BlockWrite(PNG_DestFile^, TypeBuf, 4, Wr);

 PNG_IDATCRC := LongInt($FFFFFFFF);
 PNG_IDATCRCByte(TypeBuf[0]);
 PNG_IDATCRCByte(TypeBuf[1]);
 PNG_IDATCRCByte(TypeBuf[2]);
 PNG_IDATCRCByte(TypeBuf[3]);

 { zlib header : CMF=0x78 (deflate, 32K window), FLG=0x01 (compute checksum). }
 PNG_IDATByte($78);
 PNG_IDATByte($01);

 PNG_Adler_A := 1;
 PNG_Adler_B := 0;
 PNG_IDATRemaining   := TotalRaw;
 PNG_IDATBlockRemain := 0;

 If TotalRaw <= 0 Then PNG_WriteStoredHeader(0, 1);
End;

{ Ecrit un bloc d'octets de donnees image dans le flux IDAT (decoupe en blocs }
{ stored de PNG_MaxStoredBlock octets selon besoin).                          }
Procedure PNG_WriteIDATBytes(Const Data: Array of Byte; Len: LongInt);
Var
 I, Chunk, BlockLen: LongInt;
 IsLast: Byte;
 SrcIdx: LongInt;
Begin
 SrcIdx := 0;
 While Len > 0 Do Begin
  If PNG_IDATBlockRemain = 0 Then Begin
   If PNG_IDATRemaining > PNG_MaxStoredBlock Then BlockLen := PNG_MaxStoredBlock
                                              Else BlockLen := PNG_IDATRemaining;
   If BlockLen = PNG_IDATRemaining Then IsLast := 1 Else IsLast := 0;
   PNG_WriteStoredHeader(BlockLen, IsLast);
   PNG_IDATBlockRemain := BlockLen;
  End;
  If Len > PNG_IDATBlockRemain Then Chunk := PNG_IDATBlockRemain Else Chunk := Len;
  For I := 0 To Chunk - 1 Do Begin
   PNG_IDATByte(Data[SrcIdx]);
   PNG_UpdateAdler(Data[SrcIdx]);
   Inc(SrcIdx);
  End;
  Dec(Len, Chunk);
  Dec(PNG_IDATRemaining, Chunk);
  Dec(PNG_IDATBlockRemain, Chunk);
 End;
End;

{ Ferme le chunk IDAT : ecrit Adler-32 puis le CRC final. }
Procedure PNG_EndIDAT;
Var
 Adler: LongInt;
Begin
 Adler := (PNG_Adler_B Shl 16) Or PNG_Adler_A;
 PNG_IDATByte(Byte((Adler Shr 24) And $FF));
 PNG_IDATByte(Byte((Adler Shr 16) And $FF));
 PNG_IDATByte(Byte((Adler Shr 8)  And $FF));
 PNG_IDATByte(Byte( Adler         And $FF));
 PNG_IDATCRC := PNG_IDATCRC Xor LongInt($FFFFFFFF);
 PNG_WriteRawBE32(PNG_IDATCRC);
End;

{ Ecrit le chunk IDAT complet en RGB 8-bit (3 octets/pixel + 1 octet filtre/ligne). }
{ TransparentIndex >= 0 : la couleur d'index palette = TransparentIndex est        }
{ traitee comme transparente via une tRNS RGB chunk (ecrite par l'appelant).       }
Procedure WritePNGImageData(Var F: File; Width, Height: Integer; TransparentIndex: Integer);
Var
 X, Y: Integer;
 R, G, B: Byte;
 PixelColor: Byte;
 RowBuf: Array[0..8191] of Byte;     { 1 filtre + jusqu'a 2048*3 RGB bytes (avec marge) }
 RowLen: LongInt;
 TotalRaw: LongInt;
Begin
 PNG_DestFile := @F;
 RowLen := 1 + LongInt(Width) * 3;
 TotalRaw := LongInt(Height) * RowLen;

 PNG_BeginIDAT(TotalRaw);

 For Y := 0 To Height - 1 Do Begin
  RowBuf[0] := 0;  { filter = None }
  For X := 0 To Width - 1 Do Begin
   If (X < BufferWidth) And (Y < BufferHeight) Then
    PixelColor := PixelBuffer^[Y, X]
   Else
    PixelColor := 15;
   PaletteToRGB(PixelColor, R, G, B);
   RowBuf[1 + X * 3]     := R;
   RowBuf[1 + X * 3 + 1] := G;
   RowBuf[1 + X * 3 + 2] := B;
  End;
  PNG_WriteIDATBytes(RowBuf, RowLen);
 End;

 PNG_EndIDAT;
End;

{ Ã‰crire le chunk IEND }
Procedure WritePNGIEND(Var F: File);
Var
 EmptyData: Array[0..0] of Byte;
Begin
 EmptyData[0] := 0;  { Non utilisÃ© }
 WritePNGChunk(F, PNG_CHUNK_IEND, EmptyData, 0);
End;

{ Fonction principale pour sauvegarder un fichier PNG }
{ TransparentIndex: index de la couleur transparente (-1 = pas de transparence) }
Function SavePNGFile(Const FileName: String; TransparentIndex: Integer): Boolean;
Var
 F: File;
 Width, Height: Integer;
 TRNS: Array[0..5] of Byte;
 R, G, B: Byte;
Begin
 SavePNGFile := False;

 { Initialiser la table CRC }
 InitPNGCRCTable;

 If Not PrepareExportBuffer(Width, Height) Then Exit;

 { Creer le fichier }
 Assign(F, FileName);
 {$I-}
 Rewrite(F, 1);
 {$I+}
 If IOResult <> 0 Then Begin
  FreePixelBuffer;
  Exit;
 End;

 { Signature PNG (8 octets fixes) }
 WritePNGSignature(F);

 { IHDR : RGB 8-bit (3 octets/pixel, sans canal alpha) }
 WritePNGIHDR(F, Width, Height, PNG_COLOR_RGB, 8);

 { tRNS optionnel : couleur transparente unique en RGB (2 octets / canal) }
 If (TransparentIndex >= 0) And (TransparentIndex <= 15) Then Begin
  PaletteToRGB(TransparentIndex, R, G, B);
  TRNS[0] := 0; TRNS[1] := R;
  TRNS[2] := 0; TRNS[3] := G;
  TRNS[4] := 0; TRNS[5] := B;
  WritePNGChunk(F, PNG_CHUNK_tRNS, TRNS, 6);
 End;

 { IDAT streaming (gere arbitrairement les images grandes) }
 WritePNGImageData(F, Width, Height, TransparentIndex);

 { IEND }
 WritePNGIEND(F);

 Close(F);
 FreePixelBuffer;
 SavePNGFile := True;
End;

{ ============================================================================ }
{ === FIN DES FONCTIONS D'EXPORT PNG === }
{ ============================================================================ }


{ ============================================================================ }
{ === EXPORT EXTENSIONS: PCX, PPM, TIFF, WPG, XBM, BGX, FAX, DCM ============= }
{ ============================================================================ }
{ Tous ces encodeurs lisent PixelBuffer^[Y,X] (palette 16 couleurs EGA)        }
{ et produisent un fichier valide. La preparation du buffer (bbox + render)    }
{ est factorisee dans PrepareRasterExportBuffer.                              }
{ ============================================================================ }

{ Helper: prepare PixelBuffer with rendered shapes. Returns False if cannot. }
Function PrepareRasterExportBuffer(Var Width, Height: Integer): Boolean;
Var
 MinX, MinY, MaxX, MaxY: Integer;
Begin
 PrepareRasterExportBuffer := False;
 If Not CalculateDrawingBounds(MinX, MinY, MaxX, MaxY) Then Begin
  MinX := 0; MinY := WORK_AREA_TOP;
  MaxX := 640; MaxY := 480;
 End;
 Width := MaxX - MinX + 1;
 Height := MaxY - MinY + 1;
 If Width < 1 Then Width := 1;
 If Height < 1 Then Height := 1;
 If Width > 2048 Then Width := 2048;
 If Height > 2048 Then Height := 2048;
 InitPixelBuffer(Width, Height);
 AdjustShapesForBuffer(MinX, MinY);
 RenderShapesToBuffer;
 AdjustShapesForBuffer(-MinX, -MinY);
 PrepareRasterExportBuffer := True;
End;

{ Helper: capture la zone exacte du DESSIN (bounding box des Shapes[]) a       }
{ l'ecran vers PixelBuffer. Aucune barre d'outils, aucun menu, aucune        }
{ barre de statut ne peut etre incluse : on lit GetPixel uniquement entre    }
{ (MinX,MinY)-(MaxX,MaxY). Si aucune forme, renvoie False.                   }
{ Suppose que l'appelant a deja appele RefreshScreen (avec menus/dialogues   }
{ supprimes) pour rendre les formes proprement sur le canvas BGI : ainsi le  }
{ texte (OutTextXY), motifs de remplissage et autres primitives BGI sont    }
{ rendus avec leur apparence exacte.                                        }
Function CaptureCanvasToBuffer(Var Width, Height: Integer): Boolean;
Var
 MinX, MinY, MaxX, MaxY: Integer;
 X, Y: Integer;
 Pix: Word;
Begin
 CaptureCanvasToBuffer := False;
 If Not CalculateDrawingBounds(MinX, MinY, MaxX, MaxY) Then Exit;

 { Marge d'un pixel pour ne pas couper les contours, mais sans rentrer dans  }
 { la barre d'outils gauche / la barre de menu en haut.                     }
 Dec(MinX); Dec(MinY); Inc(MaxX); Inc(MaxY);
 If MinX < TOOLBAR_WIDTH + 1 Then MinX := TOOLBAR_WIDTH + 1;
 If MinY < WORK_AREA_TOP  + 1 Then MinY := WORK_AREA_TOP  + 1;
 If MaxX > ScreenWidth  - 1    Then MaxX := ScreenWidth  - 1;
 If MaxY > ScreenHeight - 17   Then MaxY := ScreenHeight - 17;
 If (MaxX <= MinX) Or (MaxY <= MinY) Then Exit;

 Width  := MaxX - MinX + 1;
 Height := MaxY - MinY + 1;
 If Width  > 2048 Then Width  := 2048;
 If Height > 2048 Then Height := 2048;
 InitPixelBuffer(Width, Height);
 For Y := 0 To Height - 1 Do
  For X := 0 To Width - 1 Do Begin
   Pix := GetPixel(MinX + X, MinY + Y);
   PixelBuffer^[Y, X] := Byte(Pix And $0F);
  End;
 CaptureCanvasToBuffer := True;
End;

{ Mode de capture pour les exports raster:                                   }
{   False = re-rendu logique a partir de Shapes[] via RenderShapesToBuffer   }
{   True  = instantane BGI a l'ecran (zone canvas), via GetPixel             }
{ Par defaut True pour reproduire le comportement Visio (WYSIWYG).           }
{ (La variable est declaree plus haut, pres de PixelBuffer.)                }

{ Helper unifie utilise par les encodeurs : selectionne le mode courant. }
Function PrepareExportBuffer(Var Width, Height: Integer): Boolean;
Begin
 If ExportFromScreen Then
  PrepareExportBuffer := CaptureCanvasToBuffer(Width, Height)
 Else
  PrepareExportBuffer := PrepareRasterExportBuffer(Width, Height);
End;

{ ---------- PCX (ZSoft Picture Exchange, 8-bit indexed, RLE) ---------- }

Procedure PCXWriteRun(Var F: File; Value, Count: Byte);
Var B: Byte;
Begin
 If Count = 0 Then Exit;
 If (Count > 1) Or (Value >= $C0) Then Begin
  B := $C0 Or Count;
  BlockWrite(F, B, 1);
  BlockWrite(F, Value, 1);
 End Else
  BlockWrite(F, Value, 1);
End;

Procedure PCXEncodeRow(Var F: File; Y, Width, BPL: Integer);
Var
 X: Integer;
 Run, V, Cur: Byte;
Begin
 V := PixelBuffer^[Y, 0];
 Run := 1;
 For X := 1 To BPL - 1 Do Begin
  If X < Width Then Cur := PixelBuffer^[Y, X]
               Else Cur := 0;
  If (Cur = V) And (Run < 63) Then
   Inc(Run)
  Else Begin
   PCXWriteRun(F, V, Run);
   V := Cur;
   Run := 1;
  End;
 End;
 PCXWriteRun(F, V, Run);
End;

Function SavePCXFile(Const FileName: String): Boolean;
Var
 F: File;
 Width, Height, Y, I: Integer;
 BPL: Integer;
 Header: Array[0..127] of Byte;
 PaletteMarker: Byte;
 R, G, B: Byte;
Begin
 SavePCXFile := False;
 If Not PrepareExportBuffer(Width, Height) Then Exit;

 BPL := Width;
 If Odd(BPL) Then Inc(BPL);

 Assign(F, FileName);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Begin FreePixelBuffer; Exit; End;

 FillChar(Header, SizeOf(Header), 0);
 Header[0]  := 10;             { Manufacturer ZSoft }
 Header[1]  := 5;              { Version PB 3.0+    }
 Header[2]  := 1;              { Encoding RLE       }
 Header[3]  := 8;              { Bits per pixel     }
 Header[4]  := 0; Header[5]  := 0;      { Xmin = 0 }
 Header[6]  := 0; Header[7]  := 0;      { Ymin = 0 }
 Header[8]  := Lo(Word(Width - 1));  Header[9]  := Hi(Word(Width - 1));
 Header[10] := Lo(Word(Height - 1)); Header[11] := Hi(Word(Height - 1));
 Header[12] := 72; Header[13] := 0;     { HDpi = 72 }
 Header[14] := 72; Header[15] := 0;     { VDpi = 72 }
 { 16-color EGA palette at offset 16 (48 bytes) }
 For I := 0 To 15 Do Begin
  PaletteToRGB(I, R, G, B);
  Header[16 + I*3 + 0] := R;
  Header[16 + I*3 + 1] := G;
  Header[16 + I*3 + 2] := B;
 End;
 Header[65] := 1;              { NPlanes }
 Header[66] := Lo(Word(BPL));
 Header[67] := Hi(Word(BPL));
 Header[68] := 1; Header[69] := 0;  { PaletteInfo = color }
 BlockWrite(F, Header, 128);

 For Y := 0 To Height - 1 Do
  PCXEncodeRow(F, Y, Width, BPL);

 { 256-color palette trailer for 8-bit PCX }
 PaletteMarker := $0C;
 BlockWrite(F, PaletteMarker, 1);
 For I := 0 To 15 Do Begin
  PaletteToRGB(I, R, G, B);
  BlockWrite(F, R, 1); BlockWrite(F, G, 1); BlockWrite(F, B, 1);
 End;
 For I := 16 To 255 Do Begin
  R := 0; BlockWrite(F, R, 1); BlockWrite(F, R, 1); BlockWrite(F, R, 1);
 End;

 Close(F);
 FreePixelBuffer;
 SavePCXFile := True;
End;

{ ---------- PPM (Portable PixMap, P6 binary 24-bit RGB) ---------- }

Function SavePPMFile(Const FileName: String): Boolean;
Var
 F: File;
 Width, Height, X, Y: Integer;
 HeaderStr: String;
 SW, SH: String;
 R, G, B: Byte;
 RGB: Array[0..2] of Byte;
Begin
 SavePPMFile := False;
 If Not PrepareExportBuffer(Width, Height) Then Exit;

 Assign(F, FileName);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Begin FreePixelBuffer; Exit; End;

 Str(Width, SW);
 Str(Height, SH);
 HeaderStr := 'P6'#10 + SW + ' ' + SH + #10 + '255'#10;
 BlockWrite(F, HeaderStr[1], Length(HeaderStr));

 For Y := 0 To Height - 1 Do
  For X := 0 To Width - 1 Do Begin
   PaletteToRGB(PixelBuffer^[Y, X], R, G, B);
   RGB[0] := R; RGB[1] := G; RGB[2] := B;
   BlockWrite(F, RGB, 3);
  End;

 Close(F);
 FreePixelBuffer;
 SavePPMFile := True;
End;

{ ---------- TIFF (Baseline 6.0, 24-bit RGB uncompressed, little-endian) ---------- }

Procedure TIFFWriteIFDEntry(Var F: File; Tag, FType: Word; Count, Value: LongInt);
Begin
 WriteWord(F, Tag);
 WriteWord(F, FType);
 WriteDWord(F, Count);
 WriteDWord(F, Value);
End;

Function SaveTIFFFile(Const FileName: String): Boolean;
Var
 F: File;
 Width, Height, X, Y: Integer;
 NumEntries: Word;
 ExternalStart, XResOffset, YResOffset, BPSOffset, StripOffset, StripBytes: LongInt;
 RGB: Array[0..2] of Byte;
 R, G, B: Byte;
 Zero: Word;
Begin
 SaveTIFFFile := False;
 If Not PrepareExportBuffer(Width, Height) Then Exit;

 Assign(F, FileName);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Begin FreePixelBuffer; Exit; End;

 StripBytes := LongInt(Width) * 3 * LongInt(Height);
 NumEntries := 12;
 { Header (8) + IFD count (2) + entries (12*NumEntries) + next-IFD (4) }
 ExternalStart := 8 + 2 + LongInt(NumEntries) * 12 + 4;
 XResOffset    := ExternalStart;
 YResOffset    := XResOffset + 8;
 BPSOffset     := YResOffset + 8;  { 3 SHORTs = 6 bytes }
 StripOffset   := BPSOffset + 6;

 { TIFF header }
 WriteWord(F, $4949);    { 'II' little-endian }
 WriteWord(F, 42);       { magic }
 WriteDWord(F, 8);       { offset to IFD }

 { IFD }
 WriteWord(F, NumEntries);
 TIFFWriteIFDEntry(F, 256, 3, 1, Width);              { ImageWidth   SHORT }
 TIFFWriteIFDEntry(F, 257, 3, 1, Height);             { ImageLength  SHORT }
 TIFFWriteIFDEntry(F, 258, 3, 3, BPSOffset);          { BitsPerSample 3xSHORT }
 TIFFWriteIFDEntry(F, 259, 3, 1, 1);                  { Compression = none }
 TIFFWriteIFDEntry(F, 262, 3, 1, 2);                  { Photometric  = RGB  }
 TIFFWriteIFDEntry(F, 273, 4, 1, StripOffset);        { StripOffsets LONG  }
 TIFFWriteIFDEntry(F, 277, 3, 1, 3);                  { SamplesPerPixel    }
 TIFFWriteIFDEntry(F, 278, 4, 1, Height);             { RowsPerStrip       }
 TIFFWriteIFDEntry(F, 279, 4, 1, StripBytes);         { StripByteCounts    }
 TIFFWriteIFDEntry(F, 282, 5, 1, XResOffset);         { XResolution        }
 TIFFWriteIFDEntry(F, 283, 5, 1, YResOffset);         { YResolution        }
 TIFFWriteIFDEntry(F, 296, 3, 1, 2);                  { ResolutionUnit=inch}
 WriteDWord(F, 0);       { next IFD = none }

 { External data: XResolution, YResolution, BitsPerSample }
 WriteDWord(F, 72); WriteDWord(F, 1);   { 72/1 dpi }
 WriteDWord(F, 72); WriteDWord(F, 1);
 WriteWord(F, 8); WriteWord(F, 8); WriteWord(F, 8); { 3xSHORT BitsPerSample }

 { Strip data: RGB pixels, top-to-bottom }
 For Y := 0 To Height - 1 Do
  For X := 0 To Width - 1 Do Begin
   PaletteToRGB(PixelBuffer^[Y, X], R, G, B);
   RGB[0] := R; RGB[1] := G; RGB[2] := B;
   BlockWrite(F, RGB, 3);
  End;

 Close(F);
 FreePixelBuffer;
 Zero := 0; { suppress unused warning }
 If Zero = 1 Then ;
 SaveTIFFFile := True;
End;

{ ---------- LBM (Electronic Arts IFF/ILBM, planar, 4 plans = 16 couleurs) ---------- }

Function SaveLBMFile(Const FileName: String): Boolean;
Var
 F: File;
 Width, Height, X, Y, I: Integer;
 Plane: Integer;
 RowBytes: Word;
 PlaneRow: Array[0..511] of Byte;
 BMHDBuf: Array[0..19] of Byte;
 CMAPBuf: Array[0..47] of Byte;
 IdBuf: Array[0..3] of Char;
 BodyStart, BodyEnd, FormStart, FormEnd: LongInt;
 Size: LongInt;
 Pix, BitVal, ByteIdx, BitInByte: Byte;
 R, G, B: Byte;
 PadByte: Byte;
 DummyW: Word;

 Procedure WriteBE16Local(Value: Word);
 Var Bb: Array[0..1] of Byte;
 Begin
  Bb[0] := Hi(Value); Bb[1] := Lo(Value);
  BlockWrite(F, Bb, 2);
 End;

 Procedure WriteBE32Local(Value: LongInt);
 Var Bb: Array[0..3] of Byte;
 Begin
  Bb[0] := Byte((Value Shr 24) And $FF);
  Bb[1] := Byte((Value Shr 16) And $FF);
  Bb[2] := Byte((Value Shr  8) And $FF);
  Bb[3] := Byte( Value         And $FF);
  BlockWrite(F, Bb, 4);
 End;

 Procedure WriteId(Const Id: String);
 Var Bb: Array[0..3] of Char; Ii: Integer;
 Begin
  For Ii := 0 To 3 Do
   If (Ii + 1) <= Length(Id) Then Bb[Ii] := Id[Ii + 1]
                              Else Bb[Ii] := ' ';
  BlockWrite(F, Bb, 4);
 End;

Begin
 SaveLBMFile := False;
 If Not PrepareExportBuffer(Width, Height) Then Exit;
 Assign(F, FileName);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Begin FreePixelBuffer; Exit; End;
 RowBytes := Word(((Word(Width) + 15) Div 16) * 2);
 { FORM <size> ILBM ... }
 WriteId('FORM');
 FormStart := FilePos(F);
 WriteBE32Local(0);                 { placeholder }
 WriteId('ILBM');
 { BMHD chunk: 20 bytes BE }
 BMHDBuf[ 0] := Byte((Width  Shr 8) And $FF);  BMHDBuf[ 1] := Byte(Width  And $FF);
 BMHDBuf[ 2] := Byte((Height Shr 8) And $FF);  BMHDBuf[ 3] := Byte(Height And $FF);
 BMHDBuf[ 4] := 0; BMHDBuf[ 5] := 0;
 BMHDBuf[ 6] := 0; BMHDBuf[ 7] := 0;
 BMHDBuf[ 8] := 4;                  { nPlanes = 4 (16 couleurs EGA) }
 BMHDBuf[ 9] := 0;                  { masking }
 BMHDBuf[10] := 0;                  { compression : aucune }
 BMHDBuf[11] := 0;
 BMHDBuf[12] := 0; BMHDBuf[13] := 0;
 BMHDBuf[14] := 1; BMHDBuf[15] := 1;
 BMHDBuf[16] := BMHDBuf[ 0]; BMHDBuf[17] := BMHDBuf[ 1];
 BMHDBuf[18] := BMHDBuf[ 2]; BMHDBuf[19] := BMHDBuf[ 3];
 WriteId('BMHD'); WriteBE32Local(20);
 BlockWrite(F, BMHDBuf, 20);
 { CMAP chunk: 16 entrees * 3 octets = 48 octets }
 For I := 0 To 15 Do Begin
  PaletteToRGB(I, R, G, B);
  CMAPBuf[I*3+0] := R; CMAPBuf[I*3+1] := G; CMAPBuf[I*3+2] := B;
 End;
 WriteId('CMAP'); WriteBE32Local(48);
 BlockWrite(F, CMAPBuf, 48);
 { BODY chunk }
 WriteId('BODY');
 BodyStart := FilePos(F);
 WriteBE32Local(0);                 { placeholder taille BODY }
 For Y := 0 To Height - 1 Do
  For Plane := 0 To 3 Do Begin
   FillChar(PlaneRow, RowBytes, 0);
   For X := 0 To Width - 1 Do Begin
    Pix := PixelBuffer^[Y, X];
    BitVal := (Pix Shr Plane) And 1;
    If BitVal <> 0 Then Begin
     ByteIdx   := Byte(X Shr 3);
     BitInByte := Byte(7 - (X And 7));
     PlaneRow[ByteIdx] := PlaneRow[ByteIdx] Or Byte(1 Shl BitInByte);
    End;
   End;
   BlockWrite(F, PlaneRow, RowBytes);
  End;
 BodyEnd := FilePos(F);
 Size := BodyEnd - BodyStart - 4;
 Seek(F, BodyStart); WriteBE32Local(Size);
 Seek(F, BodyEnd);
 If (Size And 1) <> 0 Then Begin
  PadByte := 0; BlockWrite(F, PadByte, 1);
 End;
 { Fix FORM size }
 FormEnd := FilePos(F);
 Size := FormEnd - FormStart - 4;
 Seek(F, FormStart); WriteBE32Local(Size);
 Seek(F, FormEnd);
 Close(F);
 FreePixelBuffer;
 IdBuf[0] := ' '; DummyW := 0; { suppress unused warnings }
 If DummyW <> 0 Then ;
 SaveLBMFile := True;
End;

{ ---------- CR2 (Canon RAW 2 minimal, conteneur TIFF LE + CFA Bayer 16 bits) ---------- }

Function SaveCR2File(Const FileName: String): Boolean;
Const
 MakeText     = 'Canon'#0;
 ModelText    = 'Canon EOS 5D'#0;
 SoftwareText = 'CloneDRAW VISIO'#0;
 DateTimeText = '2026:01:01 00:00:00'#0;
Var
 F: File;
 Width, Height: Integer;
 X, Y: Integer;
 R, G, B: Byte;
 Raw8: Byte;
 Raw16: Word;
 NumEntries: Word;
 XResOffset, YResOffset: LongInt;
 MakeOffset, ModelOffset, SoftwareOffset, DateTimeOffset: LongInt;
 ColorMatrixOffset, StripOffset, StripByteCount: LongInt;

 Procedure W8(Bb: Byte);
 Begin BlockWrite(F, Bb, 1); End;

 Procedure W16(W: Word);
 Var Bb: Array[0..1] of Byte;
 Begin
  Bb[0] := Byte(W And $FF); Bb[1] := Byte((W Shr 8) And $FF);
  BlockWrite(F, Bb, 2);
 End;

 Procedure W32(L: LongInt);
 Var Bb: Array[0..3] of Byte;
 Begin
  Bb[0] := Byte(L And $FF);
  Bb[1] := Byte((L Shr  8) And $FF);
  Bb[2] := Byte((L Shr 16) And $FF);
  Bb[3] := Byte((L Shr 24) And $FF);
  BlockWrite(F, Bb, 4);
 End;

 Procedure IFDEntry(Tag, FType: Word; Count, Value: LongInt);
 Begin W16(Tag); W16(FType); W32(Count); W32(Value); End;

 Procedure WriteStr(Const S: String);
 Var Ii: Integer; C: Char;
 Begin
  For Ii := 1 To Length(S) Do Begin
   C := S[Ii]; BlockWrite(F, C, 1);
  End;
 End;

Begin
 SaveCR2File := False;
 If Not PrepareExportBuffer(Width, Height) Then Exit;
 Assign(F, FileName);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Begin FreePixelBuffer; Exit; End;
 NumEntries := 25;
 XResOffset := 16 + 2 + LongInt(NumEntries) * 12 + 4;
 YResOffset := XResOffset + 8;
 MakeOffset := YResOffset + 8;
 ModelOffset    := MakeOffset     + Length(MakeText);
 SoftwareOffset := ModelOffset    + Length(ModelText);
 DateTimeOffset := SoftwareOffset + Length(SoftwareText);
 ColorMatrixOffset := DateTimeOffset + Length(DateTimeText);
 StripOffset    := ColorMatrixOffset + 72;
 StripByteCount := LongInt(Width) * LongInt(Height) * 2;
 { TIFF header LE + CR2 marker }
 W16($4949); W16(42); W32(16);
 W8(Ord('C')); W8(Ord('R')); W16(2); W32(0);
 { IFD0 }
 W16(NumEntries);
 IFDEntry(256, 4, 1, LongInt(Width));
 IFDEntry(257, 4, 1, LongInt(Height));
 IFDEntry(258, 3, 1, 16);
 IFDEntry(259, 3, 1, 1);                  { Compression = none }
 IFDEntry(262, 3, 1, 32803);              { Photometric = CFA }
 IFDEntry(271, 2, Length(MakeText),     MakeOffset);
 IFDEntry(272, 2, Length(ModelText),    ModelOffset);
 IFDEntry(273, 4, 1, StripOffset);
 IFDEntry(274, 3, 1, 1);
 IFDEntry(277, 3, 1, 1);
 IFDEntry(278, 4, 1, LongInt(Height));
 IFDEntry(279, 4, 1, StripByteCount);
 IFDEntry(282, 5, 1, XResOffset);
 IFDEntry(283, 5, 1, YResOffset);
 IFDEntry(284, 3, 1, 1);
 IFDEntry(296, 3, 1, 2);
 IFDEntry(305, 2, Length(SoftwareText), SoftwareOffset);
 IFDEntry(306, 2, Length(DateTimeText), DateTimeOffset);
 IFDEntry(33421, 3, 2, LongInt($00020002));
 IFDEntry(33422, 1, 4, LongInt($02010100));
 IFDEntry(50710, 1, 3, LongInt($00020100));
 IFDEntry(50711, 3, 1, 1);
 IFDEntry(50714, 4, 1, 0);
 IFDEntry(50717, 4, 1, 65535);
 IFDEntry(50721, 10, 9, ColorMatrixOffset);
 W32(0);
 { Donnees referencees }
 W32(72); W32(1); W32(72); W32(1);
 WriteStr(MakeText); WriteStr(ModelText);
 WriteStr(SoftwareText); WriteStr(DateTimeText);
 { Matrice neutre 3x3 (SRationals) }
 W32(1); W32(1); W32(0); W32(1); W32(0); W32(1);
 W32(0); W32(1); W32(1); W32(1); W32(0); W32(1);
 W32(0); W32(1); W32(0); W32(1); W32(1); W32(1);
 { Strip CFA Bayer RGGB 16 bits }
 For Y := 0 To Height - 1 Do
  For X := 0 To Width - 1 Do Begin
   PaletteToRGB(PixelBuffer^[Y, X], R, G, B);
   If (Y And 1) = 0 Then Begin
    If (X And 1) = 0 Then Raw8 := R Else Raw8 := G;
   End Else Begin
    If (X And 1) = 0 Then Raw8 := G Else Raw8 := B;
   End;
   Raw16 := Word(Raw8) * 257;
   W16(Raw16);
  End;
 Close(F);
 FreePixelBuffer;
 SaveCR2File := True;
End;

{ ---------- CUT (Dr. HALO, 8-bit indexed, RLE-mark $80) ---------- }

Function SaveCUTFile(Const FileName: String): Boolean;
Var
 F: File;
 Width, Height, X, Y: Integer;
 Hdr: Array[0..5] of Byte;
 PixLine: Array[0..2047] of Byte;
 RLEBuf:  Array[0..4159] of Byte;
 Pos, DestPos: Word;
 RunLen, LitLen, K: Word;
 RLELen: Word;
 EndMarker: Word;
Begin
 SaveCUTFile := False;
 If Not PrepareExportBuffer(Width, Height) Then Exit;
 Assign(F, FileName);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Begin FreePixelBuffer; Exit; End;
 Hdr[0] := Lo(Word(Width));  Hdr[1] := Hi(Word(Width));
 Hdr[2] := Lo(Word(Height)); Hdr[3] := Hi(Word(Height));
 Hdr[4] := 0; Hdr[5] := 0;
 BlockWrite(F, Hdr, 6);
 For Y := 0 To Height - 1 Do Begin
  For X := 0 To Width - 1 Do PixLine[X] := PixelBuffer^[Y, X];
  { Encodage RLE Dr.HALO }
  Pos := 0; DestPos := 0;
  While Pos < Word(Width) Do Begin
   RunLen := 1;
   While (Pos + RunLen < Word(Width)) And (RunLen < 127) And
         (PixLine[Pos + RunLen] = PixLine[Pos]) Do Inc(RunLen);
   If RunLen >= 2 Then Begin
    RLEBuf[DestPos]     := $80 Or Byte(RunLen);
    RLEBuf[DestPos + 1] := PixLine[Pos];
    Inc(DestPos, 2); Inc(Pos, RunLen);
   End Else Begin
    LitLen := 0;
    While (Pos + LitLen < Word(Width)) And (LitLen < 127) Do Begin
     If (Pos + LitLen + 1 < Word(Width)) And
        (PixLine[Pos + LitLen] = PixLine[Pos + LitLen + 1]) Then Break;
     Inc(LitLen);
    End;
    If LitLen = 0 Then LitLen := 1;
    RLEBuf[DestPos] := Byte(LitLen); Inc(DestPos);
    For K := 0 To LitLen - 1 Do
     RLEBuf[DestPos + K] := PixLine[Pos + K];
    Inc(DestPos, LitLen); Inc(Pos, LitLen);
   End;
  End;
  RLEBuf[DestPos] := 0; Inc(DestPos);
  RLELen := DestPos;
  BlockWrite(F, RLELen, 2);
  BlockWrite(F, RLEBuf, RLELen);
 End;
 EndMarker := 0;
 BlockWrite(F, EndMarker, 2);
 Close(F);
 FreePixelBuffer;
 SaveCUTFile := True;
End;

{ ---------- GEM/IMG (Digital Research, big-endian, 4 plans + XIMG) ---------- }

Function SaveGEMFile(Const FileName: String): Boolean;
Var
 F: File;
 Width, Height, X, Y, I, Plane: Integer;
 PlaneBytes: Word;
 PlaneBuf: Array[0..511] of Byte;
 Pix, Idx: Byte;
 R, G, B: Byte;
 P, LStart: Word;
 RunByte, Cmd: Byte;
 RunCount, EmitN: Word;
 RVal, GVal, BVal: Word;
 HdrLen: Word;

 Procedure W16BE(W: Word);
 Var Bb: Array[0..1] of Byte;
 Begin
  Bb[0] := Hi(W); Bb[1] := Lo(W); BlockWrite(F, Bb, 2);
 End;

 Procedure W8(Bb: Byte);
 Begin BlockWrite(F, Bb, 1); End;

 Function ToGEM(C: Byte): Word;
 Begin ToGEM := Word((LongInt(C) * 1000 + 127) Div 255); End;

Begin
 SaveGEMFile := False;
 If Not PrepareExportBuffer(Width, Height) Then Exit;
 Assign(F, FileName);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Begin FreePixelBuffer; Exit; End;
 PlaneBytes := Word((LongInt(Width) + 7) Div 8);
 HdrLen := Word(11 + 3 * 16);     { 4 plans + XIMG 16 entrees }
 W16BE(1);                         { Version }
 W16BE(HdrLen);                    { HeaderLen en mots 16 bits }
 W16BE(4);                         { NumPlanes }
 W16BE(2);                         { PatternLen }
 W16BE(372); W16BE(372);           { PixelDim }
 W16BE(Word(Width)); W16BE(Word(Height));
 W8(Ord('X')); W8(Ord('I')); W8(Ord('M')); W8(Ord('G'));
 W16BE(0);                         { ColorModelRGB }
 For I := 0 To 15 Do Begin
  PaletteToRGB(I, R, G, B);
  RVal := ToGEM(R); GVal := ToGEM(G); BVal := ToGEM(B);
  W16BE(RVal); W16BE(GVal); W16BE(BVal);
 End;
 For Y := 0 To Height - 1 Do
  For Plane := 0 To 3 Do Begin
   FillChar(PlaneBuf, PlaneBytes, 0);
   For X := 0 To Width - 1 Do Begin
    Pix := PixelBuffer^[Y, X];
    Idx := Pix;
    If ((Idx Shr Plane) And 1) <> 0 Then
     PlaneBuf[X Shr 3] := PlaneBuf[X Shr 3] Or Byte(1 Shl (7 - (X And 7)));
   End;
   { Encode RLE GEM }
   P := 0;
   While P < PlaneBytes Do Begin
    RunByte := PlaneBuf[P];
    If (RunByte = 0) Or (RunByte = $FF) Then Begin
     RunCount := 1;
     While (P + RunCount < PlaneBytes) And
           (PlaneBuf[P + RunCount] = RunByte) Do Inc(RunCount);
     While RunCount > 0 Do Begin
      If RunCount > 127 Then EmitN := 127
                        Else EmitN := RunCount;
      If RunByte = 0 Then Cmd := Byte(EmitN)
                     Else Cmd := Byte($80 Or EmitN);
      W8(Cmd);
      Dec(RunCount, EmitN); Inc(P, EmitN);
     End;
    End Else Begin
     LStart := P;
     While (P < PlaneBytes) And (PlaneBuf[P] <> 0) And
           (PlaneBuf[P] <> $FF) And (P - LStart < 255) Do Inc(P);
     EmitN := P - LStart;
     W8($80); W8(Byte(EmitN));
     BlockWrite(F, PlaneBuf[LStart], EmitN);
    End;
   End;
  End;
 Close(F);
 FreePixelBuffer;
 SaveGEMFile := True;
End;

{ ---------- HDR (Radiance RGBE, 4 octets/pixel, en-tete ASCII) ---------- }

Function SaveHDRFile(Const FileName: String): Boolean;
Var
 F: File;
 Width, Height, X, Y: Integer;
 R, G, B: Byte;
 MaxC: Word;
 ExpValue: Byte;
 Pow2: Word;
 Scale: Real;
 RGBE: Array[0..3] of Byte;

 Procedure WriteText(Const S: String);
 Var Ii: Integer; C: Char;
 Begin
  For Ii := 1 To Length(S) Do Begin
   C := S[Ii]; BlockWrite(F, C, 1);
  End;
 End;

 Function NumStr(V: LongInt): String;
 Var S: String;
 Begin
  Str(V, S);
  While (Length(S) > 0) And (S[1] = ' ') Do Delete(S, 1, 1);
  NumStr := S;
 End;

Begin
 SaveHDRFile := False;
 If Not PrepareExportBuffer(Width, Height) Then Exit;
 Assign(F, FileName);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Begin FreePixelBuffer; Exit; End;
 WriteText('#?RADIANCE'#10);
 WriteText('SOFTWARE=CloneDRAW VISIO'#10);
 WriteText('FORMAT=32-bit_rle_rgbe'#10);
 WriteText('EXPOSURE=1.0000000000000'#10);
 WriteText(#10);
 WriteText('-Y ' + NumStr(Height) + ' +X ' + NumStr(Width) + #10);
 For Y := 0 To Height - 1 Do
  For X := 0 To Width - 1 Do Begin
   PaletteToRGB(PixelBuffer^[Y, X], R, G, B);
   MaxC := R;
   If G > MaxC Then MaxC := G;
   If B > MaxC Then MaxC := B;
   If MaxC = 0 Then Begin
    RGBE[0] := 0; RGBE[1] := 0; RGBE[2] := 0; RGBE[3] := 0;
   End Else Begin
    ExpValue := 0; Pow2 := 1;
    While Pow2 <= MaxC Do Begin Pow2 := Pow2 Shl 1; Inc(ExpValue); End;
    Scale := 256.0 / Pow2;
    RGBE[0] := Byte(Round(R * Scale));
    RGBE[1] := Byte(Round(G * Scale));
    RGBE[2] := Byte(Round(B * Scale));
    RGBE[3] := Byte(ExpValue + 128);
   End;
   BlockWrite(F, RGBE, 4);
  End;
 Close(F);
 FreePixelBuffer;
 SaveHDRFile := True;
End;

{ ---------- MAC (MacPaint Apple, 576x720 monochrome, PackBits) ---------- }

Function SaveMACFile(Const FileName: String): Boolean;
Const
 MacW = 576; MacH = 720; MacRB = 72;
Var
 F: File;
 Width, Height, X, Y, I: Integer;
 ZeroByte, PadByte: Byte;
 RowBuf:  Array[0..MacRB - 1] of Byte;
 PackBuf: Array[0..MacRB * 2 + 1] of Byte;
 Pos, DestPos: Word;
 RunLen, LitLen, K: Word;
 PixVal: Byte;
 IsBlack: Boolean;
Begin
 SaveMACFile := False;
 If Not PrepareExportBuffer(Width, Height) Then Exit;
 Assign(F, FileName);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Begin FreePixelBuffer; Exit; End;
 { En-tete 512 octets a zero }
 ZeroByte := 0;
 For I := 1 To 512 Do BlockWrite(F, ZeroByte, 1);
 { 720 lignes PackBits }
 For Y := 0 To MacH - 1 Do Begin
  FillChar(RowBuf, MacRB, 0);
  If Y < Height Then
   For X := 0 To MacW - 1 Do
    If X < Width Then Begin
     PixVal := PixelBuffer^[Y, X];
     { Indice EGA < 8 = couleur sombre, sinon claire ;
       indice 0 noir, 15 blanc. Heuristique : < 8 => noir. }
     IsBlack := (PixVal < 8) And (PixVal <> 7);
     If PixVal = 7 Then IsBlack := False; { 7 = gris clair }
     If IsBlack Then
      RowBuf[X Shr 3] := RowBuf[X Shr 3] Or Byte(1 Shl (7 - (X And 7)));
    End;
  { PackBits compress }
  Pos := 0; DestPos := 0;
  While Pos < MacRB Do Begin
   RunLen := 1;
   While (Pos + RunLen < MacRB) And (RunLen < 128) And
         (RowBuf[Pos + RunLen] = RowBuf[Pos]) Do Inc(RunLen);
   If RunLen >= 3 Then Begin
    PackBuf[DestPos]     := Byte(257 - RunLen);
    PackBuf[DestPos + 1] := RowBuf[Pos];
    Inc(DestPos, 2); Inc(Pos, RunLen);
   End Else Begin
    LitLen := 0;
    While (Pos + LitLen < MacRB) And (LitLen < 128) Do Begin
     If (Pos + LitLen + 2 < MacRB) And
        (RowBuf[Pos + LitLen]     = RowBuf[Pos + LitLen + 1]) And
        (RowBuf[Pos + LitLen + 1] = RowBuf[Pos + LitLen + 2]) Then Break;
     Inc(LitLen);
    End;
    If LitLen = 0 Then LitLen := 1;
    PackBuf[DestPos] := Byte(LitLen - 1); Inc(DestPos);
    For K := 0 To LitLen - 1 Do PackBuf[DestPos + K] := RowBuf[Pos + K];
    Inc(DestPos, LitLen); Inc(Pos, LitLen);
   End;
  End;
  BlockWrite(F, PackBuf, DestPos);
 End;
 Close(F);
 FreePixelBuffer;
 PadByte := 0; If PadByte = 1 Then ; { suppress unused }
 SaveMACFile := True;
End;

{ ---------- MSP (Microsoft Paint v1 "DanM", 1bpp non compresse) ---------- }

Function SaveMSPFile(Const FileName: String): Boolean;
Var
 F: File;
 Width, Height, X, Y: Integer;
 BytesPerLine: Word;
 OutLine: Array[0..511] of Byte;
 Hdr: Array[0..31] of Byte;
 PixVal: Byte;
 IsInk: Boolean;
 W: Word;

 Procedure SetW(Off: Integer; Val: Word);
 Begin
  Hdr[Off]   := Byte(Val And $FF);
  Hdr[Off+1] := Byte((Val Shr 8) And $FF);
 End;

 Function GetW(Off: Integer): Word;
 Begin
  GetW := Word(Hdr[Off]) Or (Word(Hdr[Off+1]) Shl 8);
 End;

Begin
 SaveMSPFile := False;
 If Not PrepareExportBuffer(Width, Height) Then Exit;
 Assign(F, FileName);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Begin FreePixelBuffer; Exit; End;
 BytesPerLine := Word((LongInt(Width) + 7) Div 8);
 FillChar(Hdr, 32, 0);
 SetW(0,  $6144);                  { 'D','a' }
 SetW(2,  $4D6E);                  { 'n','M' }
 SetW(4,  Word(Width));
 SetW(6,  Word(Height));
 SetW(8,  1); SetW(10, 1);
 SetW(12, Word(Width));
 SetW(14, Word(Height));
 SetW(16, 0); SetW(18, 0);
 W := 0;
 W := W Xor GetW(0);  W := W Xor GetW(2);
 W := W Xor GetW(4);  W := W Xor GetW(6);
 W := W Xor GetW(8);  W := W Xor GetW(10);
 W := W Xor GetW(12); W := W Xor GetW(14);
 W := W Xor GetW(16); W := W Xor GetW(18);
 SetW(20, W);
 BlockWrite(F, Hdr, 32);
 For Y := 0 To Height - 1 Do Begin
  FillChar(OutLine, BytesPerLine, 0);
  For X := 0 To Width - 1 Do Begin
   PixVal := PixelBuffer^[Y, X];
   { Convention MSP : bit 1 = encre (noir). Heuristique : indice
     EGA 0..7 sombre (sauf 7=gris clair) considere comme encre. }
   IsInk := (PixVal < 8) And (PixVal <> 7);
   If IsInk Then
    OutLine[X Shr 3] := OutLine[X Shr 3] Or Byte(1 Shl (7 - (X And 7)));
  End;
  BlockWrite(F, OutLine, BytesPerLine);
 End;
 Close(F);
 FreePixelBuffer;
 SaveMSPFile := True;
End;

{ ---------- WPG (WordPerfect Graphics 1.0, 8-bit indexed, BE multi-byte) ---------- }

Procedure WPGWriteWordBE(Var F: File; W: Word);
Var Buf: Array[0..1] of Byte;
Begin
 Buf[0] := Hi(W); Buf[1] := Lo(W);
 BlockWrite(F, Buf, 2);
End;

Procedure WPGWriteLongBE(Var F: File; L: LongInt);
Var Buf: Array[0..3] of Byte;
Begin
 Buf[0] := Byte((L Shr 24) And $FF);
 Buf[1] := Byte((L Shr 16) And $FF);
 Buf[2] := Byte((L Shr 8) And $FF);
 Buf[3] := Byte(L And $FF);
 BlockWrite(F, Buf, 4);
End;

Procedure WPGWriteRecLen(Var F: File; Len: LongInt);
Var B: Byte;
Begin
 If Len < $FF Then Begin
  B := Byte(Len);
  BlockWrite(F, B, 1);
 End Else Begin
  B := $FF; BlockWrite(F, B, 1);
  WPGWriteWordBE(F, Word(Len));
 End;
End;

Function SaveWPGFile(Const FileName: String): Boolean;
{ Exporteur WPG VECTORIEL (WordPerfect Graphics 1.0).
  Au lieu de rasteriser le dessin, on emet directement les primitives
  vectorielles (rectangle, ligne, polygone, ellipse approchee). Tous les
  champs multi-octets sont en little-endian conformement au format WPG. }
Const
 WPG_REC_FILLATTR  = $01;
 WPG_REC_LINEATTR  = $02;
 WPG_REC_POLYLINE  = $06;
 WPG_REC_RECTANGLE = $07;
 WPG_REC_POLYGON   = $08;
 WPG_REC_COLORMAP  = $0E;
 WPG_REC_START     = $0F;
 WPG_REC_END       = $10;
Var
 F: File;
 I, J, K: Integer;
 MinX, MinY, MaxX, MaxY: Integer;
 PicW, PicH: LongInt;
 OffX, OffY: Integer;
 LastLineCol, LastFillCol: Integer;
 NPts: Integer;
 PolyX: Array[0..127] of Word;
 PolyY: Array[0..127] of Word;
 RecBuf: Array[0..1023] of Byte;
 RecPos: Integer;
 R, G, B: Byte;
 TmpHdr: Array[0..15] of Byte;

 Procedure RBufInit;
 Begin RecPos := 0; End;

 Procedure RBufByte(Bb: Byte);
 Begin RecBuf[RecPos] := Bb; Inc(RecPos); End;

 Procedure RBufWordLE(W: Word);
 Begin
  RecBuf[RecPos]   := Byte(W And $FF);
  RecBuf[RecPos+1] := Byte((W Shr 8) And $FF);
  Inc(RecPos, 2);
 End;

 Procedure EmitRecord(RecType: Byte);
 Var Hdr: Array[0..3] of Byte; HLen: Integer;
 Begin
  Hdr[0] := RecType;
  If RecPos < $FF Then Begin
   Hdr[1] := Byte(RecPos);
   HLen := 2;
  End Else Begin
   Hdr[1] := $FF;
   Hdr[2] := Byte(RecPos And $FF);
   Hdr[3] := Byte((RecPos Shr 8) And $FF);
   HLen := 4;
  End;
  BlockWrite(F, Hdr, HLen);
  If RecPos > 0 Then BlockWrite(F, RecBuf, RecPos);
 End;

 Function MapX(VX: Integer): Word;
 Var T: LongInt;
 Begin
  T := LongInt(VX) - LongInt(OffX);
  If T < 0 Then T := 0;
  If T > 65535 Then T := 65535;
  MapX := Word(T);
 End;

 Function MapY(VY: Integer): Word;
 Var T: LongInt;
 Begin
  { WPG : axe Y vers le haut, origine en bas a gauche. Inverser. }
  T := PicH - (LongInt(VY) - LongInt(OffY));
  If T < 0 Then T := 0;
  If T > 65535 Then T := 65535;
  MapY := Word(T);
 End;

 Procedure EmitLineAttr(ColorIdx: Integer);
 Begin
  If ColorIdx = LastLineCol Then Exit;
  LastLineCol := ColorIdx;
  RBufInit;
  RBufByte(1);                  { Style = solid }
  RBufByte(Byte(ColorIdx And $FF));
  EmitRecord(WPG_REC_LINEATTR);
 End;

 Procedure EmitFillAttr(ColorIdx: Integer);
 Begin
  If ColorIdx = LastFillCol Then Exit;
  LastFillCol := ColorIdx;
  RBufInit;
  If ColorIdx < 0 Then Begin
   RBufByte(0);                 { Style = none }
   RBufByte(0);
  End Else Begin
   RBufByte(1);                 { Style = solid }
   RBufByte(Byte(ColorIdx And $FF));
  End;
  EmitRecord(WPG_REC_FILLATTR);
 End;

 Procedure EmitRectangleRec(X1, Y1, X2, Y2: Integer);
 Var WX1, WY1, WW, WH: Word; T: Integer; A, B2: LongInt;
 Begin
  If X1 > X2 Then Begin T := X1; X1 := X2; X2 := T; End;
  If Y1 > Y2 Then Begin T := Y1; Y1 := Y2; Y2 := T; End;
  { WPG rectangle : x,y est le coin BAS-gauche en coords WPG. }
  WX1 := MapX(X1);
  WY1 := MapY(Y2);              { coin bas en visio = y2 (max) }
  A := LongInt(MapX(X2)) - LongInt(WX1);
  B2:= LongInt(MapY(Y1)) - LongInt(WY1);
  If A < 0 Then A := 0; If A > 65535 Then A := 65535;
  If B2< 0 Then B2:= 0; If B2> 65535 Then B2:= 65535;
  WW := Word(A); WH := Word(B2);
  RBufInit;
  RBufWordLE(WX1); RBufWordLE(WY1);
  RBufWordLE(WW);  RBufWordLE(WH);
  EmitRecord(WPG_REC_RECTANGLE);
 End;

 Procedure EmitPolyPoints(RecType: Byte);
 Var Ii: Integer;
 Begin
  RBufInit;
  RBufWordLE(Word(NPts));
  For Ii := 0 To NPts - 1 Do Begin
   RBufWordLE(PolyX[Ii]);
   RBufWordLE(PolyY[Ii]);
  End;
  EmitRecord(RecType);
 End;

 Procedure AddPoint(VX, VY: Integer);
 Begin
  If NPts > 127 Then Exit;
  PolyX[NPts] := MapX(VX);
  PolyY[NPts] := MapY(VY);
  Inc(NPts);
 End;

 Procedure ApproxEllipse(X1, Y1, X2, Y2: Integer);
 Var Cx, Cy, Rx, Ry: LongInt;
     Step: Integer;
     Theta: Real;
     Px, Py: Integer;
 Begin
  Cx := (LongInt(X1) + LongInt(X2)) Div 2;
  Cy := (LongInt(Y1) + LongInt(Y2)) Div 2;
  Rx := Abs(LongInt(X2) - LongInt(X1)) Div 2;
  Ry := Abs(LongInt(Y2) - LongInt(Y1)) Div 2;
  NPts := 0;
  For Step := 0 To 35 Do Begin
   Theta := Step * (2.0 * Pi / 36.0);
   Px := Integer(Cx + Round(Rx * Cos(Theta)));
   Py := Integer(Cy + Round(Ry * Sin(Theta)));
   AddPoint(Px, Py);
  End;
  { Fermer le polygone }
  AddPoint(Integer(Cx + Rx), Integer(Cy));
 End;

 Procedure ApproxBezier(Const Pts: TPointArray; Cnt: Integer);
 Var Step: Integer; T: Real;
     X0, Y0, X1c, Y1c, X2c, Y2c, X3, Y3: Integer;
     Bx, By: Real;
     OneMt, OneMt2, OneMt3, T2, T3: Real;
 Begin
  NPts := 0;
  If Cnt < 4 Then Exit;
  X0 := Pts[1].X; Y0 := Pts[1].Y;
  X1c:= Pts[2].X; Y1c:= Pts[2].Y;
  X2c:= Pts[3].X; Y2c:= Pts[3].Y;
  X3 := Pts[4].X; Y3 := Pts[4].Y;
  For Step := 0 To 30 Do Begin
   T := Step / 30.0;
   OneMt := 1.0 - T;
   OneMt2:= OneMt * OneMt;
   OneMt3:= OneMt2 * OneMt;
   T2 := T * T;
   T3 := T2 * T;
   Bx := OneMt3*X0 + 3*OneMt2*T*X1c + 3*OneMt*T2*X2c + T3*X3;
   By := OneMt3*Y0 + 3*OneMt2*T*Y1c + 3*OneMt*T2*Y2c + T3*Y3;
   AddPoint(Round(Bx), Round(By));
  End;
 End;

Begin
 SaveWPGFile := False;
 If ShapeCount <= 0 Then Begin
  If Not CalculateDrawingBounds(MinX, MinY, MaxX, MaxY) Then Exit;
 End Else Begin
  If Not CalculateDrawingBounds(MinX, MinY, MaxX, MaxY) Then Exit;
 End;
 { Ajouter une marge }
 Dec(MinX, 10); Dec(MinY, 10);
 Inc(MaxX, 10); Inc(MaxY, 10);
 OffX := MinX; OffY := MinY;
 PicW := LongInt(MaxX) - LongInt(MinX);
 PicH := LongInt(MaxY) - LongInt(MinY);
 If PicW < 1 Then PicW := 1;
 If PicH < 1 Then PicH := 1;
 If PicW > 65535 Then PicW := 65535;
 If PicH > 65535 Then PicH := 65535;

 Assign(F, FileName);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Exit;

 { ===== En-tete WPG fixe ===== }
 TmpHdr[0]  := $FF;
 TmpHdr[1]  := Ord('W');
 TmpHdr[2]  := Ord('P');
 TmpHdr[3]  := Ord('C');
 TmpHdr[4]  := 16; TmpHdr[5] := 0; TmpHdr[6] := 0; TmpHdr[7] := 0; { DataOffset LE }
 TmpHdr[8]  := 1;     { ProductType }
 TmpHdr[9]  := $16;   { FileType = graphics }
 TmpHdr[10] := 1;     { Major version }
 TmpHdr[11] := 0;     { Minor version }
 TmpHdr[12] := 0; TmpHdr[13] := 0; TmpHdr[14] := 0; TmpHdr[15] := 0;
 BlockWrite(F, TmpHdr, 16);

 { ===== Record Start ===== }
 RBufInit;
 RBufByte(1);                   { Version }
 RBufByte(0);                   { Flags }
 RBufWordLE(Word(PicW));
 RBufWordLE(Word(PicH));
 EmitRecord(WPG_REC_START);

 { ===== ColorMap : palette EGA 16 couleurs ===== }
 RBufInit;
 RBufWordLE(0);                 { Start index }
 RBufWordLE(16);                { Count }
 For I := 0 To 15 Do Begin
  PaletteToRGB(I, R, G, B);
  RBufByte(R); RBufByte(G); RBufByte(B);
 End;
 EmitRecord(WPG_REC_COLORMAP);

 { ===== Emettre les formes ===== }
 LastLineCol := -2;
 LastFillCol := -2;

 For I := 1 To ShapeCount Do Begin
  Case Shapes[I].ShapeType Of
   stRectangle: Begin
    EmitLineAttr(Shapes[I].LineColor);
    EmitFillAttr(Shapes[I].FillColor);
    EmitRectangleRec(Shapes[I].X1, Shapes[I].Y1,
                     Shapes[I].X2, Shapes[I].Y2);
   End;
   stEllipse: Begin
    EmitLineAttr(Shapes[I].LineColor);
    EmitFillAttr(Shapes[I].FillColor);
    ApproxEllipse(Shapes[I].X1, Shapes[I].Y1,
                  Shapes[I].X2, Shapes[I].Y2);
    EmitPolyPoints(WPG_REC_POLYGON);
   End;
   stLine, stConnector: Begin
    EmitLineAttr(Shapes[I].LineColor);
    NPts := 0;
    AddPoint(Shapes[I].X1, Shapes[I].Y1);
    AddPoint(Shapes[I].X2, Shapes[I].Y2);
    EmitPolyPoints(WPG_REC_POLYLINE);
   End;
   stPolygon: Begin
    If Shapes[I].PointCount >= 2 Then Begin
     EmitLineAttr(Shapes[I].LineColor);
     EmitFillAttr(Shapes[I].FillColor);
     NPts := 0;
     For J := 1 To Shapes[I].PointCount Do
      AddPoint(Shapes[I].Points[J].X, Shapes[I].Points[J].Y);
     If Shapes[I].PointCount >= 3 Then
      EmitPolyPoints(WPG_REC_POLYGON)
     Else
      EmitPolyPoints(WPG_REC_POLYLINE);
    End;
   End;
   stBezier: Begin
    If Shapes[I].PointCount >= 4 Then Begin
     EmitLineAttr(Shapes[I].LineColor);
     ApproxBezier(Shapes[I].Points, Shapes[I].PointCount);
     EmitPolyPoints(WPG_REC_POLYLINE);
    End;
   End;
   { stText, stImage : pas de support vectoriel direct dans WPG 1.0 simple }
  End;
  K := 0; If K <> 0 Then ; { silence compiler }
 End;

 { ===== Record End ===== }
 RBufInit;
 EmitRecord(WPG_REC_END);

 Close(F);
 SaveWPGFile := True;
End;

{ ---------- XBM (X11 Bitmap, 1-bit ASCII C array) ---------- }

Function XBMShortName(Const FileName: String): String;
Var I, J: Integer; S: String;
Begin
 J := 0;
 For I := Length(FileName) DownTo 1 Do
  If (FileName[I] = '\') Or (FileName[I] = '/') Or (FileName[I] = ':') Then Begin
   J := I; Break;
  End;
 S := Copy(FileName, J + 1, 255);
 J := Pos('.', S);
 If J > 0 Then S := Copy(S, 1, J - 1);
 { Sanitize: replace non-alnum by underscore }
 For I := 1 To Length(S) Do
  If Not (((S[I] >= 'A') And (S[I] <= 'Z')) Or
          ((S[I] >= 'a') And (S[I] <= 'z')) Or
          ((S[I] >= '0') And (S[I] <= '9'))) Then S[I] := '_';
 If S = '' Then S := 'image';
 XBMShortName := S;
End;

{ Convert palette index to 1-bit (0 = black/foreground, 1 = white/background) }
Function XBMPaletteToBit(Idx: Byte): Byte;
Var R, G, B: Byte;
Begin
 PaletteToRGB(Idx, R, G, B);
 { Threshold on luminance ~ 128 }
 If (LongInt(R) + LongInt(G) + LongInt(B)) >= 384 Then XBMPaletteToBit := 0
                                                   Else XBMPaletteToBit := 1;
End;

Procedure XBMWriteStr(Var F: File; Const S: String);
Begin
 If Length(S) > 0 Then BlockWrite(F, S[1], Length(S));
End;

Function SaveXBMFile(Const FileName: String): Boolean;
Var
 F: File;
 Width, Height, X, Y: Integer;
 Name, S, Hex: String;
 RowBytes, I, Col: Integer;
 B, Bit: Byte;
 HexDigits: String;
Begin
 SaveXBMFile := False;
 HexDigits := '0123456789ABCDEF';
 If Not PrepareExportBuffer(Width, Height) Then Exit;

 Assign(F, FileName);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Begin FreePixelBuffer; Exit; End;

 Name := XBMShortName(FileName);
 Str(Width, S);
 XBMWriteStr(F, '#define ' + Name + '_width ' + S + #10);
 Str(Height, S);
 XBMWriteStr(F, '#define ' + Name + '_height ' + S + #10);
 XBMWriteStr(F, 'static unsigned char ' + Name + '_bits[] = {' + #10);

 RowBytes := (Width + 7) Div 8;
 Col := 0;
 For Y := 0 To Height - 1 Do Begin
  For I := 0 To RowBytes - 1 Do Begin
   B := 0;
   For X := 0 To 7 Do Begin
    If I*8 + X < Width Then Bit := XBMPaletteToBit(PixelBuffer^[Y, I*8 + X])
                       Else Bit := 0;
    If Bit <> 0 Then B := B Or (1 Shl X);
   End;
   Hex := '0x' + HexDigits[((B Shr 4) And $0F) + 1] + HexDigits[(B And $0F) + 1];
   If (Y = Height - 1) And (I = RowBytes - 1) Then XBMWriteStr(F, ' ' + Hex)
   Else Begin
    XBMWriteStr(F, ' ' + Hex + ',');
    Inc(Col);
    If Col >= 12 Then Begin XBMWriteStr(F, #10); Col := 0; End;
   End;
  End;
 End;
 XBMWriteStr(F, #10 + '};' + #10);

 Close(F);
 FreePixelBuffer;
 SaveXBMFile := True;
End;

{ ---------- BGX (MonsterBook 8-bit raw, signature 'BGX1') ---------- }

Function SaveBGXFile(Const FileName: String): Boolean;
Var
 F: File;
 Width, Height, X, Y: Integer;
 Sig: Array[0..3] of Char;
 W16, H16: Word;
 Bpp: Byte;
 Pix: Byte;
Begin
 SaveBGXFile := False;
 If Not PrepareExportBuffer(Width, Height) Then Exit;

 Assign(F, FileName);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Begin FreePixelBuffer; Exit; End;

 Sig[0] := 'B'; Sig[1] := 'G'; Sig[2] := 'X'; Sig[3] := '1';
 BlockWrite(F, Sig, 4);
 W16 := Word(Width);  WriteWord(F, W16);
 H16 := Word(Height); WriteWord(F, H16);
 Bpp := 8;            BlockWrite(F, Bpp, 1);

 For Y := 0 To Height - 1 Do
  For X := 0 To Width - 1 Do Begin
   Pix := PixelBuffer^[Y, X];
   BlockWrite(F, Pix, 1);
  End;

 Close(F);
 FreePixelBuffer;
 SaveBGXFile := True;
End;

{ ---------- FAX (CCITT G3 1D, MH encoding) ---------- }

Const
 FAX_EOL = '000000000001';

Var
 FAX_OutByte: Byte;
 FAX_OutBits: Byte;

Procedure FAXWriteBit(Var F: File; Bit: Byte);
Var B: Byte;
Begin
 If (Bit And 1) <> 0 Then
  FAX_OutByte := FAX_OutByte Or (Byte(1) Shl (7 - FAX_OutBits));
 Inc(FAX_OutBits);
 If FAX_OutBits = 8 Then Begin
  B := FAX_OutByte;
  BlockWrite(F, B, 1);
  FAX_OutByte := 0;
  FAX_OutBits := 0;
 End;
End;

Procedure FAXWriteCode(Var F: File; Const Code: String);
Var I: Integer;
Begin
 For I := 1 To Length(Code) Do
  If Code[I] = '1' Then FAXWriteBit(F, 1)
                   Else FAXWriteBit(F, 0);
End;

Procedure FAXFlush(Var F: File);
Var B: Byte;
Begin
 If FAX_OutBits <> 0 Then Begin
  B := FAX_OutByte;
  BlockWrite(F, B, 1);
  FAX_OutByte := 0; FAX_OutBits := 0;
 End;
End;

Function FAXWhiteTC(Run: Byte): String;
Begin
 Case Run of
  0:FAXWhiteTC:='00110101';   1:FAXWhiteTC:='000111';
  2:FAXWhiteTC:='0111';       3:FAXWhiteTC:='1000';
  4:FAXWhiteTC:='1011';       5:FAXWhiteTC:='1100';
  6:FAXWhiteTC:='1110';       7:FAXWhiteTC:='1111';
  8:FAXWhiteTC:='10011';      9:FAXWhiteTC:='10100';
  10:FAXWhiteTC:='00111';     11:FAXWhiteTC:='01000';
  12:FAXWhiteTC:='001000';    13:FAXWhiteTC:='000011';
  14:FAXWhiteTC:='110100';    15:FAXWhiteTC:='110101';
  16:FAXWhiteTC:='101010';    17:FAXWhiteTC:='101011';
  18:FAXWhiteTC:='0100111';   19:FAXWhiteTC:='0001100';
  20:FAXWhiteTC:='0001000';   21:FAXWhiteTC:='0010111';
  22:FAXWhiteTC:='0000011';   23:FAXWhiteTC:='0000100';
  24:FAXWhiteTC:='0101000';   25:FAXWhiteTC:='0101011';
  26:FAXWhiteTC:='0010011';   27:FAXWhiteTC:='0100100';
  28:FAXWhiteTC:='0011000';   29:FAXWhiteTC:='00000010';
  30:FAXWhiteTC:='00000011';  31:FAXWhiteTC:='00011010';
  32:FAXWhiteTC:='00011011';  33:FAXWhiteTC:='00010010';
  34:FAXWhiteTC:='00010011';  35:FAXWhiteTC:='00010100';
  36:FAXWhiteTC:='00010101';  37:FAXWhiteTC:='00010110';
  38:FAXWhiteTC:='00010111';  39:FAXWhiteTC:='00101000';
  40:FAXWhiteTC:='00101001';  41:FAXWhiteTC:='00101010';
  42:FAXWhiteTC:='00101011';  43:FAXWhiteTC:='00101100';
  44:FAXWhiteTC:='00101101';  45:FAXWhiteTC:='00000100';
  46:FAXWhiteTC:='00000101';  47:FAXWhiteTC:='00001010';
  48:FAXWhiteTC:='00001011';  49:FAXWhiteTC:='01010010';
  50:FAXWhiteTC:='01010011';  51:FAXWhiteTC:='01010100';
  52:FAXWhiteTC:='01010101';  53:FAXWhiteTC:='00100100';
  54:FAXWhiteTC:='00100101';  55:FAXWhiteTC:='01011000';
  56:FAXWhiteTC:='01011001';  57:FAXWhiteTC:='01011010';
  58:FAXWhiteTC:='01011011';  59:FAXWhiteTC:='01001010';
  60:FAXWhiteTC:='01001011';  61:FAXWhiteTC:='00110010';
  62:FAXWhiteTC:='00110011';  Else FAXWhiteTC:='00110100';
 End;
End;

Function FAXBlackTC(Run: Byte): String;
Begin
 Case Run of
  0:FAXBlackTC:='0000110111';   1:FAXBlackTC:='010';
  2:FAXBlackTC:='11';            3:FAXBlackTC:='10';
  4:FAXBlackTC:='011';           5:FAXBlackTC:='0011';
  6:FAXBlackTC:='0010';          7:FAXBlackTC:='00011';
  8:FAXBlackTC:='000101';        9:FAXBlackTC:='000100';
  10:FAXBlackTC:='0000100';     11:FAXBlackTC:='0000101';
  12:FAXBlackTC:='0000111';     13:FAXBlackTC:='00000100';
  14:FAXBlackTC:='00000111';    15:FAXBlackTC:='000011000';
  16:FAXBlackTC:='0000010111';  17:FAXBlackTC:='0000011000';
  18:FAXBlackTC:='0000001000';  19:FAXBlackTC:='00001100111';
  20:FAXBlackTC:='00001101000'; 21:FAXBlackTC:='00001101100';
  22:FAXBlackTC:='00000110111'; 23:FAXBlackTC:='00000101000';
  24:FAXBlackTC:='00000010111'; 25:FAXBlackTC:='00000011000';
  26:FAXBlackTC:='000011001010';27:FAXBlackTC:='000011001011';
  28:FAXBlackTC:='000011001100';29:FAXBlackTC:='000011001101';
  30:FAXBlackTC:='000001101000';31:FAXBlackTC:='000001101001';
  32:FAXBlackTC:='000001101010';33:FAXBlackTC:='000001101011';
  34:FAXBlackTC:='000011010010';35:FAXBlackTC:='000011010011';
  36:FAXBlackTC:='000011010100';37:FAXBlackTC:='000011010101';
  38:FAXBlackTC:='000011010110';39:FAXBlackTC:='000011010111';
  40:FAXBlackTC:='000001101100';41:FAXBlackTC:='000001101101';
  42:FAXBlackTC:='000011011010';43:FAXBlackTC:='000011011011';
  44:FAXBlackTC:='000001010100';45:FAXBlackTC:='000001010101';
  46:FAXBlackTC:='000001010110';47:FAXBlackTC:='000001010111';
  48:FAXBlackTC:='000001100100';49:FAXBlackTC:='000001100101';
  50:FAXBlackTC:='000001010010';51:FAXBlackTC:='000001010011';
  52:FAXBlackTC:='000000100100';53:FAXBlackTC:='000000110111';
  54:FAXBlackTC:='000000111000';55:FAXBlackTC:='000000100111';
  56:FAXBlackTC:='000000101000';57:FAXBlackTC:='000001011000';
  58:FAXBlackTC:='000001011001';59:FAXBlackTC:='000000101011';
  60:FAXBlackTC:='000000101100';61:FAXBlackTC:='000001011010';
  62:FAXBlackTC:='000001100110';Else FAXBlackTC:='000001100111';
 End;
End;

Function FAXMakeup(Run: Word; Black: Boolean): String;
Begin
 Case Run of
  64: If Black Then FAXMakeup:='0000001111'   Else FAXMakeup:='11011';
  128:If Black Then FAXMakeup:='000011001000' Else FAXMakeup:='10010';
  192:If Black Then FAXMakeup:='000011001001' Else FAXMakeup:='010111';
  256:If Black Then FAXMakeup:='000001011011' Else FAXMakeup:='0110111';
  320:If Black Then FAXMakeup:='000000110011' Else FAXMakeup:='00110110';
  384:If Black Then FAXMakeup:='000000110100' Else FAXMakeup:='00110111';
  448:If Black Then FAXMakeup:='000000110101' Else FAXMakeup:='01100100';
  512:If Black Then FAXMakeup:='0000001101100'Else FAXMakeup:='01100101';
  576:If Black Then FAXMakeup:='0000001101101'Else FAXMakeup:='01101000';
  640:If Black Then FAXMakeup:='0000001001010'Else FAXMakeup:='01100111';
  704:If Black Then FAXMakeup:='0000001001011'Else FAXMakeup:='011001100';
  768:If Black Then FAXMakeup:='0000001001100'Else FAXMakeup:='011001101';
  832:If Black Then FAXMakeup:='0000001001101'Else FAXMakeup:='011010010';
  896:If Black Then FAXMakeup:='0000001110010'Else FAXMakeup:='011010011';
  960:If Black Then FAXMakeup:='0000001110011'Else FAXMakeup:='011010100';
  1024:If Black Then FAXMakeup:='0000001110100'Else FAXMakeup:='011010101';
  1088:If Black Then FAXMakeup:='0000001110101'Else FAXMakeup:='011010110';
  1152:If Black Then FAXMakeup:='0000001110110'Else FAXMakeup:='011010111';
  1216:If Black Then FAXMakeup:='0000001110111'Else FAXMakeup:='011011000';
  1280:If Black Then FAXMakeup:='0000001010010'Else FAXMakeup:='011011001';
  1344:If Black Then FAXMakeup:='0000001010011'Else FAXMakeup:='011011010';
  1408:If Black Then FAXMakeup:='0000001010100'Else FAXMakeup:='011011011';
  1472:If Black Then FAXMakeup:='0000001010101'Else FAXMakeup:='010011000';
  1536:If Black Then FAXMakeup:='0000001011010'Else FAXMakeup:='010011001';
  1600:If Black Then FAXMakeup:='0000001011011'Else FAXMakeup:='010011010';
  1664:If Black Then FAXMakeup:='0000001100100'Else FAXMakeup:='011000';
  1728:If Black Then FAXMakeup:='0000001100101'Else FAXMakeup:='010011011';
  Else FAXMakeup:='00000001111';
 End;
End;

Procedure FAXWriteRun(Var F: File; Run: Word; Black: Boolean);
Var Makeup: Word;
Begin
 While Run >= 1792 Do Begin
  FAXWriteCode(F, FAXMakeup(1728, Black));
  Dec(Run, 1728);
 End;
 If Run >= 64 Then Begin
  Makeup := (Run Div 64) * 64;
  FAXWriteCode(F, FAXMakeup(Makeup, Black));
  Run := Run Mod 64;
 End;
 If Black Then FAXWriteCode(F, FAXBlackTC(Byte(Run)))
          Else FAXWriteCode(F, FAXWhiteTC(Byte(Run)));
End;

Function SaveFAXFile(Const FileName: String): Boolean;
Var
 F: File;
 Width, Height, X, Y: Integer;
 R, G, B: Byte;
 CurBlack: Boolean;
 CurBit, RunLen: Word;
 PixIsBlack: Boolean;
Begin
 SaveFAXFile := False;
 If Not PrepareExportBuffer(Width, Height) Then Exit;

 Assign(F, FileName);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Begin FreePixelBuffer; Exit; End;

 FAX_OutByte := 0;
 FAX_OutBits := 0;
 { Leading EOL }
 FAXWriteCode(F, FAX_EOL);
 For Y := 0 To Height - 1 Do Begin
  { Each line starts with a white run (possibly zero) }
  CurBlack := False;
  RunLen := 0;
  For X := 0 To Width - 1 Do Begin
   PaletteToRGB(PixelBuffer^[Y, X], R, G, B);
   PixIsBlack := (LongInt(R) + LongInt(G) + LongInt(B)) < 384;
   If PixIsBlack = CurBlack Then Inc(RunLen)
   Else Begin
    FAXWriteRun(F, RunLen, CurBlack);
    CurBlack := PixIsBlack;
    RunLen := 1;
   End;
  End;
  FAXWriteRun(F, RunLen, CurBlack);
  FAXWriteCode(F, FAX_EOL);
 End;
 { 6 trailing EOLs (RTC) }
 For X := 0 To 4 Do FAXWriteCode(F, FAX_EOL);
 FAXFlush(F);

 { Suppress unused warning on local CurBit }
 CurBit := 0; If CurBit = 1 Then ;

 Close(F);
 FreePixelBuffer;
 SaveFAXFile := True;
End;

{ ---------- DCM (DICOM Secondary Capture, 8-bit grayscale uncompressed) ---------- }

Procedure DCMWriteStr(Var F: File; Const S: String);
Begin
 If Length(S) > 0 Then BlockWrite(F, S[1], Length(S));
End;

Procedure DCMWritePadded(Var F: File; Const S: String; PadCh: Char);
Var L: Integer; C: Char;
Begin
 If Length(S) > 0 Then BlockWrite(F, S[1], Length(S));
 If Odd(Length(S)) Then Begin C := PadCh; BlockWrite(F, C, 1); End;
 L := 0; If L = 1 Then ;
End;

Procedure DCMWriteTag(Var F: File; Group, Element: Word);
Begin
 WriteWord(F, Group);
 WriteWord(F, Element);
End;

Procedure DCMWriteVR(Var F: File; Const VR: String);
Var Buf: Array[0..1] of Char;
Begin
 If Length(VR) >= 2 Then Begin Buf[0] := VR[1]; Buf[1] := VR[2]; End
                    Else Begin Buf[0] := ' '; Buf[1] := ' '; End;
 BlockWrite(F, Buf, 2);
End;

Procedure DCMWriteElemStr(Var F: File; G, E: Word; Const VR, Value: String);
Var L: Word; Pad: Char;
Begin
 If VR = 'UI' Then Pad := #0 Else Pad := ' ';
 L := Length(Value);
 If Odd(L) Then Inc(L);
 DCMWriteTag(F, G, E);
 DCMWriteVR(F, VR);
 WriteWord(F, L);
 DCMWritePadded(F, Value, Pad);
End;

Procedure DCMWriteElemUS(Var F: File; G, E, V: Word);
Begin
 DCMWriteTag(F, G, E);
 DCMWriteVR(F, 'US');
 WriteWord(F, 2);
 WriteWord(F, V);
End;

Procedure DCMWriteElemUL(Var F: File; G, E: Word; V: LongInt);
Begin
 DCMWriteTag(F, G, E);
 DCMWriteVR(F, 'UL');
 WriteWord(F, 4);
 WriteDWord(F, V);
End;

Function DCMPad2(W: Word): String;
Var S: String;
Begin
 Str(W, S);
 While Length(S) < 2 Do S := '0' + S;
 DCMPad2 := S;
End;

Function DCMPad4(W: Word): String;
Var S: String;
Begin
 Str(W, S);
 While Length(S) < 4 Do S := '0' + S;
 DCMPad4 := S;
End;

Function SaveDCMFile(Const FileName: String): Boolean;
Var
 F: File;
 Width, Height, X, Y: Integer;
 Preamble: Array[0..127] of Byte;
 Magic: Array[0..3] of Char;
 GroupLenPos, GroupStart, GroupEnd: LongInt;
 SOPUID, StudyUID, SeriesUID: String;
 TS: String;
 DateStr, TimeStr: String;
 Yr, Mo, Da, Dow: Word;
 Hr, Mi, Se, Hs: Word;
 PixelDataLen: LongInt;
 R, G, B, Gray: Byte;
 GroupLenVal: LongInt;
Begin
 SaveDCMFile := False;
 If Not PrepareExportBuffer(Width, Height) Then Exit;

 Assign(F, FileName);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Begin FreePixelBuffer; Exit; End;

 { 128-byte zero preamble + DICM }
 FillChar(Preamble, 128, 0);
 BlockWrite(F, Preamble, 128);
 Magic[0]:='D'; Magic[1]:='I'; Magic[2]:='C'; Magic[3]:='M';
 BlockWrite(F, Magic, 4);

 { Build deterministic-ish UIDs based on dims }
 Str(LongInt(Width) * 17 + LongInt(Height) * 31 + 1, SOPUID);
 SOPUID    := '1.2.826.0.1.3680043.10.543.2.' + SOPUID + '.1';
 Str(LongInt(Width) * 17 + LongInt(Height) * 31 + 2, StudyUID);
 StudyUID  := '1.2.826.0.1.3680043.10.543.2.' + StudyUID + '.2';
 Str(LongInt(Width) * 17 + LongInt(Height) * 31 + 3, SeriesUID);
 SeriesUID := '1.2.826.0.1.3680043.10.543.2.' + SeriesUID + '.3';
 TS := '1.2.840.10008.1.2.1';     { Explicit VR Little Endian }

 GetDate(Yr, Mo, Da, Dow);
 GetTime(Hr, Mi, Se, Hs);
 DateStr := DCMPad4(Yr) + DCMPad2(Mo) + DCMPad2(Da);
 TimeStr := DCMPad2(Hr) + DCMPad2(Mi) + DCMPad2(Se);

 { Meta group (0002,xxxx) - Explicit VR }
 { Write (0002,0000) Group Length, value patched after }
 DCMWriteTag(F, $0002, $0000);
 DCMWriteVR(F, 'UL');
 WriteWord(F, 4);
 GroupLenPos := FilePos(F);
 WriteDWord(F, 0);                 { placeholder }
 GroupStart := FilePos(F);
 { (0002,0001) File Meta Info Version OB }
 DCMWriteTag(F, $0002, $0001);
 DCMWriteVR(F, 'OB');
 WriteWord(F, 0);
 WriteDWord(F, 2);
 WriteWord(F, $0100);              { 00 01 -> as LE word 0x0100 (00 then 01) }
 { (0002,0002) Media Storage SOP Class UID UI = SecondaryCapture }
 DCMWriteElemStr(F, $0002, $0002, 'UI', '1.2.840.10008.5.1.4.1.1.7');
 { (0002,0003) Media Storage SOP Instance UID }
 DCMWriteElemStr(F, $0002, $0003, 'UI', SOPUID);
 { (0002,0010) Transfer Syntax UID }
 DCMWriteElemStr(F, $0002, $0010, 'UI', TS);
 { (0002,0012) Implementation Class UID }
 DCMWriteElemStr(F, $0002, $0012, 'UI', '1.2.826.0.1.3680043.10.543.1');
 GroupEnd := FilePos(F);
 GroupLenVal := GroupEnd - GroupStart;
 Seek(F, GroupLenPos);
 WriteDWord(F, GroupLenVal);
 Seek(F, GroupEnd);

 { Dataset - Explicit VR Little Endian }
 DCMWriteElemStr(F, $0008, $0016, 'UI', '1.2.840.10008.5.1.4.1.1.7');
 DCMWriteElemStr(F, $0008, $0018, 'UI', SOPUID);
 DCMWriteElemStr(F, $0008, $0020, 'DA', DateStr);
 DCMWriteElemStr(F, $0008, $0030, 'TM', TimeStr);
 DCMWriteElemStr(F, $0008, $0060, 'CS', 'OT');
 DCMWriteElemStr(F, $0008, $0070, 'LO', 'GLADIR');
 DCMWriteElemStr(F, $0010, $0010, 'PN', 'CLONEDRAW^EXPORT');
 DCMWriteElemStr(F, $0010, $0020, 'LO', 'CLONEDRAW-001');
 DCMWriteElemStr(F, $0020, $000D, 'UI', StudyUID);
 DCMWriteElemStr(F, $0020, $000E, 'UI', SeriesUID);
 DCMWriteElemStr(F, $0020, $0010, 'SH', '1');
 DCMWriteElemStr(F, $0020, $0011, 'IS', '1');
 DCMWriteElemStr(F, $0020, $0013, 'IS', '1');
 DCMWriteElemUS(F, $0028, $0002, 1);                 { SamplesPerPixel = 1 (grayscale) }
 DCMWriteElemStr(F, $0028, $0004, 'CS', 'MONOCHROME2');
 DCMWriteElemUS(F, $0028, $0010, Word(Height));      { Rows    }
 DCMWriteElemUS(F, $0028, $0011, Word(Width));       { Columns }
 DCMWriteElemUS(F, $0028, $0100, 8);                 { BitsAllocated }
 DCMWriteElemUS(F, $0028, $0101, 8);                 { BitsStored    }
 DCMWriteElemUS(F, $0028, $0102, 7);                 { HighBit       }
 DCMWriteElemUS(F, $0028, $0103, 0);                 { PixelRepresentation }

 PixelDataLen := LongInt(Width) * LongInt(Height);
 If Odd(PixelDataLen) Then ; { even byte length: W*H is even when either dim is even; if not, pad below }

 { (7FE0,0010) PixelData OB }
 DCMWriteTag(F, $7FE0, $0010);
 DCMWriteVR(F, 'OB');
 WriteWord(F, 0);
 If Odd(PixelDataLen) Then WriteDWord(F, PixelDataLen + 1)
                      Else WriteDWord(F, PixelDataLen);
 For Y := 0 To Height - 1 Do
  For X := 0 To Width - 1 Do Begin
   PaletteToRGB(PixelBuffer^[Y, X], R, G, B);
   Gray := Byte((LongInt(R) + LongInt(G) + LongInt(B)) Div 3);
   BlockWrite(F, Gray, 1);
  End;
 If Odd(PixelDataLen) Then Begin Gray := 0; BlockWrite(F, Gray, 1); End;

 Close(F);
 FreePixelBuffer;
 SaveDCMFile := True;
End;

{ ============================================================================ }
{ === FIN EXPORT EXTENSIONS ================================================= }
{ ============================================================================ }


{ Procedure New - Creer un nouveau document }
Procedure FileNew;
Begin
 CurrentFileName := '';
 DocumentModified := False;
 ShapeCount := 0;
 SelectedShape := 0;
 If Language = _English Then StatusMessage := 'New document'
                       Else StatusMessage := 'Nouveau document';
End;

{ Declaration forward du dialogue d'ouverture/enregistrement de fichier
  (implementation plus bas dans le fichier) }
Function ShowVisioFileDialog(SaveMode: Boolean;
                             Const DefaultName: String;
                             Var ChosenFile: String): Boolean; Forward;

Function ShowVisioExportDialog(Const DefaultName: String;
                               Var ChosenFile: String;
                               Var SelectedExt: String): Boolean; Forward;

Procedure RefreshScreen; Forward;

{ ProcÃ©dure Open - Ouvrir un fichier (dialogue style Visio) }
Procedure FileOpen;
Var
 ChosenFile: String;
 Success: Boolean;
Begin
 If Not ShowVisioFileDialog(False, '', ChosenFile) Then Begin
  If Language = _English Then StatusMessage := 'Open cancelled'
                        Else StatusMessage := 'Ouverture annulee';
  Exit;
 End;
 Success := LoadVisioFile(ChosenFile);
 If Success Then Begin
  CurrentFileName := ChosenFile;
  DocumentModified := False;
  SelectedShape := 0;
  If Language = _English Then StatusMessage := 'Opened: ' + ChosenFile
                        Else StatusMessage := 'Ouvert : ' + ChosenFile;
 End Else Begin
  If Language = _English Then StatusMessage := 'Open failed: ' + ChosenFile
                        Else StatusMessage := 'Echec ouverture : ' + ChosenFile;
 End;
End;

{ ProcÃ©dure Close - Fermer le document actuel }
Procedure FileClose;
Begin
 CurrentFileName := '';
 DocumentModified := False;
 ShapeCount := 0;
 SelectedShape := 0;
 If Language = _English Then StatusMessage := 'Document closed'
                       Else StatusMessage := 'Document ferme';
End;

{ Forward pour permettre Ã  FileSave d'appeler FileSaveAs }
Procedure FileSaveAs; Forward;

{ ProcÃ©dure Save - Sauvegarder le document }
Procedure FileSave;
Var
 Success: Boolean;
Begin
 If CurrentFileName = '' Then Begin
  { Si pas de nom de fichier, appeler Save As }
  FileSaveAs;
 End
 Else Begin
  { Sauvegarder le fichier au format appropriÃ© }
  Success := SaveVisioFile(CurrentFileName, VISIO_FORMAT_UNKNOWN);
  If Success Then Begin
   DocumentModified := False;
   If Language = _English Then StatusMessage := 'Saved: ' + CurrentFileName
                         Else StatusMessage := 'Enregistre : ' + CurrentFileName;
  End
  Else Begin
   If Language = _English Then StatusMessage := 'Save failed: ' + CurrentFileName
                         Else StatusMessage := 'Echec enregistrement : ' + CurrentFileName;
  End;
 End;
End;

{ ProcÃ©dure Save As - Sauvegarder sous un nouveau nom }
Procedure FileSaveAs;
Var
 FileName, DefName: String;
 FileFormat: Integer;
 Success: Boolean;
Begin
 If CurrentFileName <> '' Then DefName := CurrentFileName
                          Else DefName := 'document.vsdx';
 If Not ShowVisioFileDialog(True, DefName, FileName) Then Begin
  If Language = _English Then StatusMessage := 'Save As cancelled'
                        Else StatusMessage := 'Enregistrement annule';
  Exit;
 End;
 If FileName <> '' Then Begin
  { DÃ©tecter le format depuis l'extension }
  FileFormat := GetVisioFormatFromExtension(FileName);

  { Sauvegarder le fichier }
  Success := SaveVisioFile(FileName, FileFormat);
  If Success Then Begin
   CurrentFileName := FileName;
   DocumentModified := False;
   If Language = _English Then StatusMessage := 'Saved as: ' + FileName
                         Else StatusMessage := 'Enregistre sous : ' + FileName;
  End
  Else Begin
   If Language = _English Then StatusMessage := 'Save As failed: ' + FileName
                         Else StatusMessage := 'Echec enregistrement : ' + FileName;
  End;
 End;
End;

{ Helpers for FileExport }
Function ExportExt(Const FileName: String): String;
Var I, J: Integer; E: String;
Begin
 J := 0;
 For I := Length(FileName) DownTo 1 Do
  If FileName[I] = '.' Then Begin J := I; Break; End
  Else If (FileName[I] = '\') Or (FileName[I] = '/') Or (FileName[I] = ':') Then Break;
 If J = 0 Then E := ''
          Else E := Copy(FileName, J + 1, 16);
 For I := 1 To Length(E) Do
  If (E[I] >= 'a') And (E[I] <= 'z') Then E[I] := Chr(Ord(E[I]) - 32);
 ExportExt := E;
End;

{ ProcÃ©dure Export - Exporter dans un autre format }
Procedure FileExport;
Var
 FileName, DefName, Ext, FilterExt: String;
 Success: Boolean;
 TransIdx: Integer;
 SavedMenuState: TMenuState;
 SavedCtxVisible, SavedLayerVis: Boolean;
 SavedSelected: Integer;
Begin
 If CurrentFileName <> '' Then Begin
  DefName := CurrentFileName;
  Ext := ExportExt(DefName);
  If Ext <> '' Then DefName := Copy(DefName, 1, Length(DefName) - Length(Ext) - 1);
  DefName := DefName + '.png';
 End Else
  DefName := 'document.png';

 If Not ShowVisioExportDialog(DefName, FileName, FilterExt) Then Begin
  If Language = _English Then StatusMessage := 'Export cancelled'
                        Else StatusMessage := 'Export annule';
  Exit;
 End;
 If FileName = '' Then Exit;

 Ext := ExportExt(FileName);
 If Ext = '' Then Begin
  { Pas d'extension tapee : utiliser celle du filtre selectionne }
  If FilterExt = '' Then FilterExt := 'PNG';
  FileName := FileName + '.' + FilterExt;
  Ext := FilterExt;
 End;

 { Capturer le canvas BGI reel (rendu WYSIWYG : texte, motifs, styles BGI    }
 { sont preserves tels quels) MAIS en supprimant temporairement tous les     }
 { elements d'UI (menu deroulant, dialogues, menu contextuel, selection).    }
 { La capture est ensuite recadree au bounding box des Shapes[] pour exclure }
 { la barre de menus, la toolbar, la barre de statut et le fond hors-dessin. }
 SavedMenuState   := MenuState;
 SavedCtxVisible  := ContextMenuVisible;
 SavedLayerVis    := LayerDialogVisible;
 SavedSelected    := SelectedShape;
 MenuState               := msNone;
 ContextMenuVisible      := False;
 LayerDialogVisible      := False;
 SelectedShape           := 0;     { supprime les poignees de redimensionnement }

 If Ext = 'SVG' Then ExportFromScreen := False
                Else ExportFromScreen := True;
 If ExportFromScreen Then RefreshScreen;

 Success := False;
 { Indice 15 (blanc) = fond du papier -> transparent dans les formats qui le  }
 { supportent (PNG via tRNS, GIF via GCE). Pour les autres formats raster,    }
 { l'indice est ignore et le fond reste blanc.                                }
 TransIdx := 15;
 If      Ext = 'PNG'  Then Success := SavePNGFile(FileName, TransIdx)
 Else If Ext = 'GIF'  Then Success := SaveGIFFile(FileName, TransIdx)
 Else If Ext = 'JPG'  Then Success := SaveJPEGFile(FileName, 85)
 Else If Ext = 'JPEG' Then Success := SaveJPEGFile(FileName, 85)
 Else If Ext = 'BMP'  Then Success := SaveBMPFile(FileName, 24)
 Else If Ext = 'DIB'  Then Success := SaveBMPFile(FileName, 24)
 Else If Ext = 'SVG'  Then Success := SaveSVGFile(FileName)
 Else If Ext = 'PCX'  Then Success := SavePCXFile(FileName)
 Else If Ext = 'PPM'  Then Success := SavePPMFile(FileName)
 Else If Ext = 'TIF'  Then Success := SaveTIFFFile(FileName)
 Else If Ext = 'TIFF' Then Success := SaveTIFFFile(FileName)
 Else If Ext = 'WPG'  Then Success := SaveWPGFile(FileName)
 Else If Ext = 'XBM'  Then Success := SaveXBMFile(FileName)
 Else If Ext = 'BGX'  Then Success := SaveBGXFile(FileName)
 Else If Ext = 'FAX'  Then Success := SaveFAXFile(FileName)
 Else If Ext = 'DCM'  Then Success := SaveDCMFile(FileName)
 Else If Ext = 'LBM'  Then Success := SaveLBMFile(FileName)
 Else If Ext = 'CR2'  Then Success := SaveCR2File(FileName)
 Else If Ext = 'CUT'  Then Success := SaveCUTFile(FileName)
 Else If Ext = 'GEM'  Then Success := SaveGEMFile(FileName)
 Else If Ext = 'HDR'  Then Success := SaveHDRFile(FileName)
 Else If Ext = 'MAC'  Then Success := SaveMACFile(FileName)
 Else If Ext = 'MSP'  Then Success := SaveMSPFile(FileName)
 Else Begin
  If Language = _English Then StatusMessage := 'Unsupported export format: .' + Ext
                        Else StatusMessage := 'Format export non supporte : .' + Ext;
  Success := False;
 End;

 { Restaurer l'etat UI sauvegarde et redessiner l'ecran tel qu'avant export. }
 MenuState          := SavedMenuState;
 ContextMenuVisible := SavedCtxVisible;
 LayerDialogVisible := SavedLayerVis;
 SelectedShape      := SavedSelected;
 RefreshScreen;

 If Success Then Begin
  If Language = _English Then StatusMessage := 'Exported: ' + FileName
                        Else StatusMessage := 'Exporte : ' + FileName;
 End Else Begin
  If Language = _English Then StatusMessage := 'Export failed: ' + FileName
                        Else StatusMessage := 'Echec export : ' + FileName;
 End;
End;

{ ProcÃ©dure Print - Imprimer le document }
Procedure FilePrint;
Begin
 If Language = _English Then StatusMessage := 'Print: not yet implemented'
                       Else StatusMessage := 'Imprimer : non implemente';
End;

Procedure FilePrintPreview;
Begin
 If Language = _English Then StatusMessage := 'Print Preview: not yet implemented'
                       Else StatusMessage := 'Apercu impression : non implemente';
End;

{ ProcÃ©dure Exit - Quitter l'application }
Function FileExit: Boolean;
Begin
 FileExit := True;
 { TODO: VÃ©rifier si le document a Ã©tÃ© modifiÃ© et proposer de sauvegarder }
End;

{ ============================================================================ }
{ === FIN DES PROCEDURES DU MENU FILE === }
{ ============================================================================ }

{ ============================================================================ }
{ === PROCEDURES DU MENU EDIT === }
{ ============================================================================ }

Const
 MAX_UNDO_LEVELS = 50;

Var
 UndoStackIndex: Integer;
 CanUndo, CanRedo: Boolean;
 ClipboardEmpty: Boolean;
 HasSelection: Boolean;

{ ProcÃ©dure Undo - Annuler la derniÃ¨re action }
Procedure EditUndo;
Begin
 If CanUndo Then Begin
  { TODO: Restaurer l'Ã©tat prÃ©cÃ©dent depuis la pile d'annulation }
  { UndoStackIndex := UndoStackIndex - 1; }
  CanRedo := True;
 End;
End;

{ ProcÃ©dure Redo - RÃ©tablir l'action annulÃ©e }
Procedure EditRedo;
Begin
 If CanRedo Then Begin
  { TODO: Restaurer l'Ã©tat suivant depuis la pile de rÃ©tablissement }
  { UndoStackIndex := UndoStackIndex + 1; }
 End;
End;

{ ProcÃ©dure Cut - Couper la sÃ©lection }
Procedure EditCut;
Begin
 If HasSelection Then Begin
  { TODO: Copier la sÃ©lection dans le presse-papiers }
  { TODO: Supprimer la sÃ©lection du document }
  ClipboardEmpty := False;
  DocumentModified := True;
 End;
End;

{ ProcÃ©dure Copy - Copier la sÃ©lection }
Procedure EditCopy;
Begin
 If HasSelection Then Begin
  { TODO: Copier la sÃ©lection dans le presse-papiers }
  ClipboardEmpty := False;
 End;
End;

{ ProcÃ©dure Paste - Coller depuis le presse-papiers }
Procedure EditPaste;
Begin
 If Not ClipboardEmpty Then Begin
  { TODO: Coller le contenu du presse-papiers dans le document }
  DocumentModified := True;
 End;
End;

{ ProcÃ©dure Delete - Supprimer la sÃ©lection }
Procedure EditDelete;
Begin
 If HasSelection Then Begin
  { TODO: Supprimer la sÃ©lection du document }
  DocumentModified := True;
 End;
End;

{ ProcÃ©dure Select All - SÃ©lectionner tous les objets }
Procedure EditSelectAll;
Begin
 { TODO: SÃ©lectionner tous les objets du calque actif }
 HasSelection := True;
End;

{ ProcÃ©dure Find - Rechercher du texte }
Procedure EditFind;
Begin
 { TODO: Afficher une boÃ®te de dialogue de recherche }
 { TODO: Rechercher le texte dans les objets texte du document }
End;

{ ProcÃ©dure Replace - Rechercher et remplacer du texte }
Procedure EditReplace;
Begin
 { TODO: Afficher une boÃ®te de dialogue de recherche et remplacement }
 { TODO: Rechercher et remplacer le texte dans les objets texte }
End;

{ ============================================================================ }
{ === FIN DES PROCEDURES DU MENU EDIT === }
{ ============================================================================ }

{ ============================================================================ }
{ === PROCEDURES DU MENU VIEW === }
{ ============================================================================ }

Const
 MIN_ZOOM_LEVEL = 10;   { 10% }
 MAX_ZOOM_LEVEL = 400;  { 400% }
 DEFAULT_ZOOM = 100;    { 100% }
 ZOOM_STEP = 25;        { Pas de zoom de 25% }

Var
 ZoomLevel: Integer;
 ShowGrid: Boolean;
 ShowRulers: Boolean;
 ShowGuides: Boolean;
 SnapToGridEnabled: Boolean;

{ ProcÃ©dure Zoom In - Augmenter le zoom }
Procedure ViewZoomIn;
Begin
 If ZoomLevel < MAX_ZOOM_LEVEL Then Begin
  ZoomLevel := ZoomLevel + ZOOM_STEP;
  If ZoomLevel > MAX_ZOOM_LEVEL Then
   ZoomLevel := MAX_ZOOM_LEVEL;
  { TODO: Redessiner le canevas avec le nouveau niveau de zoom }
 End;
End;

{ ProcÃ©dure Zoom Out - Diminuer le zoom }
Procedure ViewZoomOut;
Begin
 If ZoomLevel > MIN_ZOOM_LEVEL Then Begin
  ZoomLevel := ZoomLevel - ZOOM_STEP;
  If ZoomLevel < MIN_ZOOM_LEVEL Then
   ZoomLevel := MIN_ZOOM_LEVEL;
  { TODO: Redessiner le canevas avec le nouveau niveau de zoom }
 End;
End;

{ ProcÃ©dure Fit Page - Ajuster le zoom pour afficher la page entiÃ¨re }
Procedure ViewFitPage;
Begin
 { TODO: Calculer le zoom optimal pour afficher la page entiÃ¨re dans la vue }
 { TODO: Appliquer ce zoom et centrer la vue sur la page }
 ZoomLevel := DEFAULT_ZOOM;
End;

{ ProcÃ©dure Grid - Activer/dÃ©sactiver l'affichage de la grille }
Procedure ViewGrid;
Begin
 ShowGrid := Not ShowGrid;
 { TODO: Redessiner le canevas avec ou sans grille }
End;

{ ProcÃ©dure Rulers - Activer/dÃ©sactiver l'affichage des rÃ¨gles }
Procedure ViewRulers;
Begin
 ShowRulers := Not ShowRulers;
 { TODO: Redessiner l'interface avec ou sans rÃ¨gles }
End;

{ ProcÃ©dure Guides - Activer/dÃ©sactiver l'affichage des guides }
Procedure ViewGuides;
Begin
 ShowGuides := Not ShowGuides;
 { TODO: Redessiner le canevas avec ou sans guides }
End;

{ ProcÃ©dure Snap to Grid - Activer/dÃ©sactiver l'accrochage Ã  la grille }
Procedure ViewSnapToGrid;
Begin
 SnapToGridEnabled := Not SnapToGridEnabled;
 { L'accrochage sera appliquÃ© lors du dÃ©placement des objets }
End;

{ ============================================================================ }
{ === FIN DES PROCEDURES DU MENU VIEW === }
{ ============================================================================ }

{ ============================================================================ }
{ === PROCEDURES DU MENU INSERT === }
{ ============================================================================ }

Var
 CurrentPage: Integer;
 PageCount: Integer;
 CurrentLayer: Integer;
 LayerCount: Integer;
 InsertMode: Integer;  { 0=None, 1=Shape, 2=TextBox, 3=Image, 4=Connector }

{ ProcÃ©dure InsertShape - InsÃ©rer une forme }
Procedure InsertShape;
Begin
 { TODO: Afficher un dialogue pour choisir le type de forme }
 { TODO: Passer en mode dessin de forme }
 InsertMode := 1;
End;

{ ProcÃ©dure InsertTextBox - InsÃ©rer une zone de texte }
Procedure InsertTextBox;
Begin
 { TODO: Passer en mode dessin de zone de texte }
 { TODO: Permettre de dessiner un rectangle pour la zone de texte }
 InsertMode := 2;
End;

{ ProcÃ©dure InsertImage - InsÃ©rer une image }
Procedure InsertImage;
Begin
 { TODO: Afficher une boÃ®te de dialogue pour sÃ©lectionner un fichier image }
 { TODO: Charger l'image et l'insÃ©rer dans le document }
 InsertMode := 3;
End;

{ ProcÃ©dure InsertConnector - InsÃ©rer un connecteur }
Procedure InsertConnector;
Begin
 { TODO: Passer en mode dessin de connecteur }
 { TODO: Permettre de connecter deux formes avec des points d'ancrage }
 InsertMode := 4;
End;

{ ProcÃ©dure InsertPage - InsÃ©rer une nouvelle page }
Procedure InsertPage;
Begin
 If PageCount < MAX_PAGES Then Begin
  PageCount := PageCount + 1;
  CurrentPage := PageCount;
  { TODO: CrÃ©er une nouvelle page vide dans le document }
  { TODO: Actualiser l'affichage pour montrer la nouvelle page }
  DocumentModified := True;
 End;
End;

{ ProcÃ©dure InsertLayer - InsÃ©rer un nouveau calque }
Procedure InsertLayer;
Var
 LayerNum: String[5];
Begin
 If LayerCount < MAX_LAYERS Then Begin
  LayerCount := LayerCount + 1;
  CurrentLayer := LayerCount;
  { Initialiser le nouveau calque }
  Str(LayerCount, LayerNum);
  Layers[LayerCount].Name := 'Layer ' + LayerNum;
  Layers[LayerCount].Visible := True;
  Layers[LayerCount].Locked := False;
  Layers[LayerCount].Color := (LayerCount mod 15) + 1; { Couleur diffÃ©rente par calque }
  DocumentModified := True;
 End;
End;

{ ProcÃ©dure InitLayer - Initialiser un calque }
Procedure InitLayer(LayerIdx: Integer; LayerName: String);
Begin
 If (LayerIdx >= 1) and (LayerIdx <= MAX_LAYERS) Then Begin
  Layers[LayerIdx].Name := LayerName;
  Layers[LayerIdx].Visible := True;
  Layers[LayerIdx].Locked := False;
  Layers[LayerIdx].Color := (LayerIdx mod 15) + 1;
 End;
End;

{ ProcÃ©dure InitAllLayers - Initialiser tous les calques }
Procedure InitAllLayers;
Var
 I: Integer;
Begin
 For I := 1 to MAX_LAYERS do Begin
  Layers[I].Name := '';
  Layers[I].Visible := True;
  Layers[I].Locked := False;
  Layers[I].Color := 1;
 End;
 { CrÃ©er le calque par dÃ©faut }
 InitLayer(1, 'Layer 1');
 LayerCount := 1;
 CurrentLayer := 1;
End;

{ Fonction pour vÃ©rifier si un calque est visible }
Function IsLayerVisible(LayerIdx: Integer): Boolean;
Begin
 If (LayerIdx >= 1) and (LayerIdx <= LayerCount) Then
  IsLayerVisible := Layers[LayerIdx].Visible
 Else
  IsLayerVisible := False;
End;

{ Fonction pour vÃ©rifier si un calque est verrouillÃ© }
Function IsLayerLocked(LayerIdx: Integer): Boolean;
Begin
 If (LayerIdx >= 1) and (LayerIdx <= LayerCount) Then
  IsLayerLocked := Layers[LayerIdx].Locked
 Else
  IsLayerLocked := True; { Par dÃ©faut, calque inexistant = verrouillÃ© }
End;

{ ProcÃ©dure pour changer la visibilitÃ© d'un calque }
Procedure SetLayerVisible(LayerIdx: Integer; Visible: Boolean);
Begin
 If (LayerIdx >= 1) and (LayerIdx <= LayerCount) Then Begin
  Layers[LayerIdx].Visible := Visible;
  DocumentModified := True;
 End;
End;

{ ProcÃ©dure pour changer le verrouillage d'un calque }
Procedure SetLayerLocked(LayerIdx: Integer; Locked: Boolean);
Begin
 If (LayerIdx >= 1) and (LayerIdx <= LayerCount) Then Begin
  Layers[LayerIdx].Locked := Locked;
  DocumentModified := True;
 End;
End;

{ ============================================================================ }
{ === FIN DES PROCEDURES DU MENU INSERT === }
{ ============================================================================ }

{ ============================================================================ }
{ === PROCEDURES DU MENU FORMAT === }
{ ============================================================================ }

Const
 DEFAULT_FILL_COLOR = White;
 DEFAULT_LINE_COLOR = Black;
 DEFAULT_LINE_WIDTH = 1;
 DEFAULT_LINE_STYLE = LINESTYLE_SOLID;
 DEFAULT_TEXT_SIZE = 10;

Type
 TAlignmentType = (atLeft, atCenter, atRight, atTop, atMiddle, atBottom);
 TArrangeType = (arBringToFront, arSendToBack, arBringForward, arSendBackward);

Var
 CurrentFillColor: Integer;
 CurrentLineColor: Integer;
 CurrentLineWidth: Integer;
 CurrentLineStyle: Integer;
 CurrentTextSize: Integer;
 CurrentAlignment: TAlignmentType;
 ObjectsGrouped: Boolean;
 { Variables pour la gestion des groupes }
 NextGroupID: Integer;        { Prochain ID de groupe Ã  attribuer }
 EditingGroupID: Integer;     { ID du groupe en cours d'Ã©dition (0 = aucun) }
 { Variables pour la boÃ®te de dialogue des propriÃ©tÃ©s }
 PropertiesDialogVisible: Boolean;
 PropDialogX, PropDialogY: Integer;
 PropSelectedColor: Integer;
 PropSelectedLineWidth: Integer;
 PropSelectedLineStyle: Integer;
 PropHighlightedButton: Integer;

{ *** BOÃŽTE DE DIALOGUE DES PROPRIÃ‰TÃ‰S *** }

{ ProcÃ©dure pour dessiner la palette de couleurs }
Procedure DrawColorPalette(X, Y: Integer; SelectedColor: Integer);
Var
 I, Row, Col: Integer;
 BoxX, BoxY: Integer;
Begin
 For I := 0 to PROP_MAX_COLORS - 1 do Begin
  Row := I div 8;
  Col := I mod 8;
  BoxX := X + Col * (PROP_COLOR_BOX_SIZE + 2);
  BoxY := Y + Row * (PROP_COLOR_BOX_SIZE + 2);

  { Dessiner la case de couleur }
  SetFillStyle(SolidFill, I);
  Bar(BoxX, BoxY, BoxX + PROP_COLOR_BOX_SIZE, BoxY + PROP_COLOR_BOX_SIZE);

  { Dessiner la bordure (plus Ã©paisse si sÃ©lectionnÃ©) }
  If I = SelectedColor Then Begin
   SetColor(Black);
   Rectangle(BoxX - 1, BoxY - 1, BoxX + PROP_COLOR_BOX_SIZE + 1, BoxY + PROP_COLOR_BOX_SIZE + 1);
   Rectangle(BoxX - 2, BoxY - 2, BoxX + PROP_COLOR_BOX_SIZE + 2, BoxY + PROP_COLOR_BOX_SIZE + 2);
  End
  Else Begin
   SetColor(PROP_DIALOG_BORDER);
   Rectangle(BoxX, BoxY, BoxX + PROP_COLOR_BOX_SIZE, BoxY + PROP_COLOR_BOX_SIZE);
  End;
 End;
End;

{ ProcÃ©dure pour dessiner les options de style de ligne }
Procedure DrawLineStyleOptions(X, Y: Integer; SelectedStyle: Integer);
Var
 I: Integer;
 LineY: Integer;
 StyleNames: Array[0..3] of String[12];
Begin
 StyleNames[0] := 'Solid';
 StyleNames[1] := 'Dashed';
 StyleNames[2] := 'Dotted';
 StyleNames[3] := 'Dash-Dot';

 For I := 0 to LINESTYLE_COUNT - 1 do Begin
  LineY := Y + I * 20;

  { Fond si sÃ©lectionnÃ© }
  If I = SelectedStyle Then Begin
   SetFillStyle(SolidFill, PROP_DIALOG_BTN_HL);
   Bar(X - 2, LineY - 2, X + 120, LineY + 14);
   SetColor(White);
  End
  Else Begin
   SetColor(PROP_DIALOG_TEXT);
  End;

  { Dessiner le nom du style }
  OutTextXY(X, LineY, StyleNames[I]);

  { Dessiner un Ã©chantillon de la ligne }
  Case I of
   LINESTYLE_SOLID: SetLineStyle(SolidLn, 0, 1);
   LINESTYLE_DASHED: SetLineStyle(DashedLn, 0, 1);
   LINESTYLE_DOTTED: SetLineStyle(DottedLn, 0, 1);
   LINESTYLE_DASHDOT: SetLineStyle(CenterLn, 0, 1);
  End;
  If I = SelectedStyle Then
   SetColor(White)
  Else
   SetColor(PROP_DIALOG_TEXT);
  Line(X + 80, LineY + 6, X + 115, LineY + 6);
  SetLineStyle(SolidLn, 0, 1);
 End;
End;

{ ProcÃ©dure pour dessiner les options d'Ã©paisseur de ligne }
Procedure DrawLineWidthOptions(X, Y: Integer; SelectedWidth: Integer);
Var
 I: Integer;
 LineY: Integer;
 WidthStr: String[5];
Begin
 For I := 1 to 5 do Begin
  LineY := Y + (I - 1) * 18;

  { Fond si sÃ©lectionnÃ© }
  If I = SelectedWidth Then Begin
   SetFillStyle(SolidFill, PROP_DIALOG_BTN_HL);
   Bar(X - 2, LineY - 2, X + 100, LineY + 14);
   SetColor(White);
  End
  Else Begin
   SetColor(PROP_DIALOG_TEXT);
  End;

  { Afficher l'Ã©paisseur }
  Str(I, WidthStr);
  OutTextXY(X, LineY, WidthStr + ' px');

  { Dessiner un Ã©chantillon de la ligne }
  SetLineStyle(SolidLn, 0, I);
  If I = SelectedWidth Then
   SetColor(White)
  Else
   SetColor(PROP_DIALOG_TEXT);
  Line(X + 40, LineY + 6, X + 95, LineY + 6);
  SetLineStyle(SolidLn, 0, 1);
 End;
End;

{ ProcÃ©dure pour dessiner la boÃ®te de dialogue des propriÃ©tÃ©s }
Procedure DrawPropertiesDialog;
Var
 DialogX, DialogY: Integer;
 SectionY: Integer;
Begin
 { Calculer la position centrÃ©e }
 DialogX := (ScreenWidth - PROP_DIALOG_WIDTH) div 2;
 DialogY := (ScreenHeight - PROP_DIALOG_HEIGHT) div 2;
 PropDialogX := DialogX;
 PropDialogY := DialogY;

 { Dessiner le fond de la boÃ®te de dialogue }
 SetFillStyle(SolidFill, PROP_DIALOG_BG);
 Bar(DialogX, DialogY, DialogX + PROP_DIALOG_WIDTH, DialogY + PROP_DIALOG_HEIGHT);

 { Dessiner la bordure }
 SetColor(PROP_DIALOG_BORDER);
 Rectangle(DialogX, DialogY, DialogX + PROP_DIALOG_WIDTH, DialogY + PROP_DIALOG_HEIGHT);
 Rectangle(DialogX + 1, DialogY + 1, DialogX + PROP_DIALOG_WIDTH - 1, DialogY + PROP_DIALOG_HEIGHT - 1);

 { Dessiner la barre de titre }
 SetFillStyle(SolidFill, Blue);
 Bar(DialogX + 2, DialogY + 2, DialogX + PROP_DIALOG_WIDTH - 2, DialogY + 20);
 SetColor(White);
 OutTextXY(DialogX + 10, DialogY + 6, 'Properties');

 { Section: Couleur de remplissage }
 SectionY := DialogY + 28;
 SetColor(PROP_DIALOG_TEXT);
 OutTextXY(DialogX + 10, SectionY, 'Fill Color:');
 DrawColorPalette(DialogX + 10, SectionY + 14, PropSelectedColor);

 { Section: Couleur de trait }
 SectionY := SectionY + 52;
 SetColor(PROP_DIALOG_TEXT);
 OutTextXY(DialogX + 10, SectionY, 'Line Color:');
 { Utiliser mÃªme palette pour couleur de trait }

 { Section: Style de ligne (Ã  droite) }
 SetColor(PROP_DIALOG_TEXT);
 OutTextXY(DialogX + 130, DialogY + 28, 'Line Style:');
 DrawLineStyleOptions(DialogX + 130, DialogY + 42, PropSelectedLineStyle);

 { Section: Ã‰paisseur de ligne }
 OutTextXY(DialogX + 130, DialogY + 130, 'Width:');
 DrawLineWidthOptions(DialogX + 130, DialogY + 144, PropSelectedLineWidth);

 { Boutons OK et Cancel }
 { Bouton OK }
 If PropHighlightedButton = 1 Then
  SetFillStyle(SolidFill, PROP_DIALOG_BTN_HL)
 Else
  SetFillStyle(SolidFill, PROP_DIALOG_BTN_BG);
 Bar(DialogX + PROP_DIALOG_WIDTH - 120, DialogY + PROP_DIALOG_HEIGHT - 28,
     DialogX + PROP_DIALOG_WIDTH - 65, DialogY + PROP_DIALOG_HEIGHT - 8);
 SetColor(PROP_DIALOG_BORDER);
 Rectangle(DialogX + PROP_DIALOG_WIDTH - 120, DialogY + PROP_DIALOG_HEIGHT - 28,
           DialogX + PROP_DIALOG_WIDTH - 65, DialogY + PROP_DIALOG_HEIGHT - 8);
 If PropHighlightedButton = 1 Then
  SetColor(White)
 Else
  SetColor(PROP_DIALOG_TEXT);
 OutTextXY(DialogX + PROP_DIALOG_WIDTH - 105, DialogY + PROP_DIALOG_HEIGHT - 24, 'OK');

 { Bouton Cancel }
 If PropHighlightedButton = 2 Then
  SetFillStyle(SolidFill, PROP_DIALOG_BTN_HL)
 Else
  SetFillStyle(SolidFill, PROP_DIALOG_BTN_BG);
 Bar(DialogX + PROP_DIALOG_WIDTH - 60, DialogY + PROP_DIALOG_HEIGHT - 28,
     DialogX + PROP_DIALOG_WIDTH - 5, DialogY + PROP_DIALOG_HEIGHT - 8);
 SetColor(PROP_DIALOG_BORDER);
 Rectangle(DialogX + PROP_DIALOG_WIDTH - 60, DialogY + PROP_DIALOG_HEIGHT - 28,
           DialogX + PROP_DIALOG_WIDTH - 5, DialogY + PROP_DIALOG_HEIGHT - 8);
 If PropHighlightedButton = 2 Then
  SetColor(White)
 Else
  SetColor(PROP_DIALOG_TEXT);
 OutTextXY(DialogX + PROP_DIALOG_WIDTH - 50, DialogY + PROP_DIALOG_HEIGHT - 24, 'Cancel');
End;

{ ProcÃ©dure pour afficher la boÃ®te de dialogue des propriÃ©tÃ©s }
Procedure ShowPropertiesDialog;
Begin
 If SelectedShape < 1 Then Exit;

 { Initialiser avec les propriÃ©tÃ©s de l'objet sÃ©lectionnÃ© }
 PropSelectedColor := Shapes[SelectedShape].FillColor;
 PropSelectedLineWidth := Shapes[SelectedShape].LineWidth;
 PropSelectedLineStyle := Shapes[SelectedShape].LineStyle;
 PropHighlightedButton := 0;

 PropertiesDialogVisible := True;
End;

{ ProcÃ©dure pour masquer la boÃ®te de dialogue des propriÃ©tÃ©s }
Procedure HidePropertiesDialog;
Begin
 PropertiesDialogVisible := False;
End;

{ Fonction pour vÃ©rifier si un clic est sur la palette de couleurs et retourner l'index }
Function GetColorAtPosition(X, Y, PaletteX, PaletteY: Integer): Integer;
Var
 Col, Row, ColorIndex: Integer;
Begin
 GetColorAtPosition := -1;

 { VÃ©rifier si dans la zone de la palette }
 If (X >= PaletteX) and (X < PaletteX + 8 * (PROP_COLOR_BOX_SIZE + 2)) and
    (Y >= PaletteY) and (Y < PaletteY + 2 * (PROP_COLOR_BOX_SIZE + 2)) Then Begin
  Col := (X - PaletteX) div (PROP_COLOR_BOX_SIZE + 2);
  Row := (Y - PaletteY) div (PROP_COLOR_BOX_SIZE + 2);
  ColorIndex := Row * 8 + Col;
  If (ColorIndex >= 0) and (ColorIndex < PROP_MAX_COLORS) Then
   GetColorAtPosition := ColorIndex;
 End;
End;

{ Fonction pour vÃ©rifier si un clic est sur les styles de ligne et retourner l'index }
Function GetLineStyleAtPosition(X, Y, OptionsX, OptionsY: Integer): Integer;
Var
 StyleIndex: Integer;
Begin
 GetLineStyleAtPosition := -1;

 { VÃ©rifier si dans la zone des options de style }
 If (X >= OptionsX - 2) and (X < OptionsX + 120) and
    (Y >= OptionsY - 2) and (Y < OptionsY + LINESTYLE_COUNT * 20) Then Begin
  StyleIndex := (Y - OptionsY + 2) div 20;
  If (StyleIndex >= 0) and (StyleIndex < LINESTYLE_COUNT) Then
   GetLineStyleAtPosition := StyleIndex;
 End;
End;

{ Fonction pour vÃ©rifier si un clic est sur les Ã©paisseurs de ligne et retourner la valeur }
Function GetLineWidthAtPosition(X, Y, OptionsX, OptionsY: Integer): Integer;
Var
 WidthIndex: Integer;
Begin
 GetLineWidthAtPosition := -1;

 { VÃ©rifier si dans la zone des options d'Ã©paisseur }
 If (X >= OptionsX - 2) and (X < OptionsX + 100) and
    (Y >= OptionsY - 2) and (Y < OptionsY + 5 * 18) Then Begin
  WidthIndex := (Y - OptionsY + 2) div 18;
  If (WidthIndex >= 0) and (WidthIndex < 5) Then
   GetLineWidthAtPosition := WidthIndex + 1;
 End;
End;

{ ProcÃ©dure pour gÃ©rer un clic dans la boÃ®te de dialogue des propriÃ©tÃ©s }
Procedure HandlePropertiesDialogClick(X, Y: Integer);
Var
 ColorIndex, StyleIndex, WidthIndex: Integer;
 DialogX, DialogY: Integer;
Begin
 If Not PropertiesDialogVisible Then Exit;

 DialogX := PropDialogX;
 DialogY := PropDialogY;

 { VÃ©rifier clic sur la palette de couleurs de remplissage }
 ColorIndex := GetColorAtPosition(X, Y, DialogX + 10, DialogY + 42);
 If ColorIndex >= 0 Then Begin
  PropSelectedColor := ColorIndex;
  Exit;
 End;

 { VÃ©rifier clic sur les styles de ligne }
 StyleIndex := GetLineStyleAtPosition(X, Y, DialogX + 130, DialogY + 42);
 If StyleIndex >= 0 Then Begin
  PropSelectedLineStyle := StyleIndex;
  Exit;
 End;

 { VÃ©rifier clic sur les Ã©paisseurs de ligne }
 WidthIndex := GetLineWidthAtPosition(X, Y, DialogX + 130, DialogY + 144);
 If WidthIndex >= 0 Then Begin
  PropSelectedLineWidth := WidthIndex;
  Exit;
 End;

 { VÃ©rifier clic sur le bouton OK }
 If (X >= DialogX + PROP_DIALOG_WIDTH - 120) and
    (X <= DialogX + PROP_DIALOG_WIDTH - 65) and
    (Y >= DialogY + PROP_DIALOG_HEIGHT - 28) and
    (Y <= DialogY + PROP_DIALOG_HEIGHT - 8) Then Begin
  { Appliquer les propriÃ©tÃ©s Ã  l'objet sÃ©lectionnÃ© }
  If SelectedShape > 0 Then Begin
   Shapes[SelectedShape].FillColor := PropSelectedColor;
   Shapes[SelectedShape].LineWidth := PropSelectedLineWidth;
   Shapes[SelectedShape].LineStyle := PropSelectedLineStyle;
   DocumentModified := True;
  End;
  HidePropertiesDialog;
  Exit;
 End;

 { VÃ©rifier clic sur le bouton Cancel }
 If (X >= DialogX + PROP_DIALOG_WIDTH - 60) and
    (X <= DialogX + PROP_DIALOG_WIDTH - 5) and
    (Y >= DialogY + PROP_DIALOG_HEIGHT - 28) and
    (Y <= DialogY + PROP_DIALOG_HEIGHT - 8) Then Begin
  HidePropertiesDialog;
  Exit;
 End;
End;

{ ProcÃ©dure pour gÃ©rer le survol dans la boÃ®te de dialogue }
Procedure HandlePropertiesDialogHover(X, Y: Integer);
Var
 DialogX, DialogY: Integer;
 OldHighlight: Integer;
Begin
 If Not PropertiesDialogVisible Then Exit;

 DialogX := PropDialogX;
 DialogY := PropDialogY;
 OldHighlight := PropHighlightedButton;
 PropHighlightedButton := 0;

 { VÃ©rifier survol du bouton OK }
 If (X >= DialogX + PROP_DIALOG_WIDTH - 120) and
    (X <= DialogX + PROP_DIALOG_WIDTH - 65) and
    (Y >= DialogY + PROP_DIALOG_HEIGHT - 28) and
    (Y <= DialogY + PROP_DIALOG_HEIGHT - 8) Then Begin
  PropHighlightedButton := 1;
 End
 { VÃ©rifier survol du bouton Cancel }
 Else If (X >= DialogX + PROP_DIALOG_WIDTH - 60) and
         (X <= DialogX + PROP_DIALOG_WIDTH - 5) and
         (Y >= DialogY + PROP_DIALOG_HEIGHT - 28) and
         (Y <= DialogY + PROP_DIALOG_HEIGHT - 8) Then Begin
  PropHighlightedButton := 2;
 End;
End;

{ *** FIN BOÃŽTE DE DIALOGUE DES PROPRIÃ‰TÃ‰S *** }

{ *** BOÃŽTE DE DIALOGUE DES CALQUES *** }

{ ProcÃ©dure pour dessiner la boÃ®te de dialogue des calques }
Procedure DrawLayerDialog;
Var
 DialogX, DialogY: Integer;
 I, ItemY: Integer;
 VisibleStr, LockedStr: String[3];
 NameStr: String[LAYER_NAME_LENGTH];
Begin
 { Calculer la position centrÃ©e }
 DialogX := (ScreenWidth - LAYER_DIALOG_WIDTH) div 2;
 DialogY := (ScreenHeight - LAYER_DIALOG_HEIGHT) div 2;
 LayerDialogX := DialogX;
 LayerDialogY := DialogY;

 { Dessiner le fond de la boÃ®te de dialogue }
 SetFillStyle(SolidFill, PROP_DIALOG_BG);
 Bar(DialogX, DialogY, DialogX + LAYER_DIALOG_WIDTH, DialogY + LAYER_DIALOG_HEIGHT);

 { Dessiner la bordure }
 SetColor(PROP_DIALOG_BORDER);
 Rectangle(DialogX, DialogY, DialogX + LAYER_DIALOG_WIDTH, DialogY + LAYER_DIALOG_HEIGHT);
 Rectangle(DialogX + 1, DialogY + 1, DialogX + LAYER_DIALOG_WIDTH - 1, DialogY + LAYER_DIALOG_HEIGHT - 1);

 { Dessiner la barre de titre }
 SetFillStyle(SolidFill, Blue);
 Bar(DialogX + 2, DialogY + 2, DialogX + LAYER_DIALOG_WIDTH - 2, DialogY + 20);
 SetColor(White);
 OutTextXY(DialogX + 10, DialogY + 6, 'Layers');

 { En-tÃªtes des colonnes }
 SetColor(PROP_DIALOG_TEXT);
 OutTextXY(DialogX + 10, DialogY + 28, 'V');   { Visible }
 OutTextXY(DialogX + 30, DialogY + 28, 'L');   { Locked }
 OutTextXY(DialogX + 50, DialogY + 28, 'Name');

 { Ligne de sÃ©paration }
 SetColor(PROP_DIALOG_BORDER);
 Line(DialogX + 5, DialogY + 40, DialogX + LAYER_DIALOG_WIDTH - 5, DialogY + 40);

 { Afficher les calques }
 For I := 1 to LayerCount do Begin
  ItemY := DialogY + 45 + (I - 1) * LAYER_ITEM_HEIGHT;

  { Surligner le calque sÃ©lectionnÃ© ou le calque actif }
  If I = LayerDialogSelectedLayer Then Begin
   SetFillStyle(SolidFill, PROP_DIALOG_BTN_HL);
   Bar(DialogX + 5, ItemY - 2, DialogX + LAYER_DIALOG_WIDTH - 5, ItemY + LAYER_ITEM_HEIGHT - 4);
   SetColor(White);
  End
  Else If I = CurrentLayer Then Begin
   SetFillStyle(SolidFill, LightGray);
   Bar(DialogX + 5, ItemY - 2, DialogX + LAYER_DIALOG_WIDTH - 5, ItemY + LAYER_ITEM_HEIGHT - 4);
   SetColor(PROP_DIALOG_TEXT);
  End
  Else Begin
   SetColor(PROP_DIALOG_TEXT);
  End;

  { Checkbox Visible }
  If Layers[I].Visible Then
   VisibleStr := '[X]'
  Else
   VisibleStr := '[ ]';
  OutTextXY(DialogX + 5, ItemY, VisibleStr);

  { Checkbox Locked }
  If Layers[I].Locked Then
   LockedStr := '[X]'
  Else
   LockedStr := '[ ]';
  OutTextXY(DialogX + 25, ItemY, LockedStr);

  { Nom du calque }
  NameStr := Layers[I].Name;
  OutTextXY(DialogX + 50, ItemY, NameStr);

  { Indicateur de couleur du calque }
  SetFillStyle(SolidFill, Layers[I].Color);
  Bar(DialogX + LAYER_DIALOG_WIDTH - 30, ItemY, DialogX + LAYER_DIALOG_WIDTH - 10, ItemY + 12);
  SetColor(PROP_DIALOG_BORDER);
  Rectangle(DialogX + LAYER_DIALOG_WIDTH - 30, ItemY, DialogX + LAYER_DIALOG_WIDTH - 10, ItemY + 12);
 End;

 { Boutons en bas }
 { Bouton New Layer }
 If LayerDialogHighlightedButton = 1 Then
  SetFillStyle(SolidFill, PROP_DIALOG_BTN_HL)
 Else
  SetFillStyle(SolidFill, PROP_DIALOG_BTN_BG);
 Bar(DialogX + 10, DialogY + LAYER_DIALOG_HEIGHT - 35,
     DialogX + 70, DialogY + LAYER_DIALOG_HEIGHT - 15);
 SetColor(PROP_DIALOG_BORDER);
 Rectangle(DialogX + 10, DialogY + LAYER_DIALOG_HEIGHT - 35,
           DialogX + 70, DialogY + LAYER_DIALOG_HEIGHT - 15);
 If LayerDialogHighlightedButton = 1 Then
  SetColor(White)
 Else
  SetColor(PROP_DIALOG_TEXT);
 OutTextXY(DialogX + 20, DialogY + LAYER_DIALOG_HEIGHT - 31, 'New');

 { Bouton Set Active }
 If LayerDialogHighlightedButton = 2 Then
  SetFillStyle(SolidFill, PROP_DIALOG_BTN_HL)
 Else
  SetFillStyle(SolidFill, PROP_DIALOG_BTN_BG);
 Bar(DialogX + 80, DialogY + LAYER_DIALOG_HEIGHT - 35,
     DialogX + 140, DialogY + LAYER_DIALOG_HEIGHT - 15);
 SetColor(PROP_DIALOG_BORDER);
 Rectangle(DialogX + 80, DialogY + LAYER_DIALOG_HEIGHT - 35,
           DialogX + 140, DialogY + LAYER_DIALOG_HEIGHT - 15);
 If LayerDialogHighlightedButton = 2 Then
  SetColor(White)
 Else
  SetColor(PROP_DIALOG_TEXT);
 OutTextXY(DialogX + 90, DialogY + LAYER_DIALOG_HEIGHT - 31, 'Active');

 { Bouton Close }
 If LayerDialogHighlightedButton = 3 Then
  SetFillStyle(SolidFill, PROP_DIALOG_BTN_HL)
 Else
  SetFillStyle(SolidFill, PROP_DIALOG_BTN_BG);
 Bar(DialogX + LAYER_DIALOG_WIDTH - 70, DialogY + LAYER_DIALOG_HEIGHT - 35,
     DialogX + LAYER_DIALOG_WIDTH - 10, DialogY + LAYER_DIALOG_HEIGHT - 15);
 SetColor(PROP_DIALOG_BORDER);
 Rectangle(DialogX + LAYER_DIALOG_WIDTH - 70, DialogY + LAYER_DIALOG_HEIGHT - 35,
           DialogX + LAYER_DIALOG_WIDTH - 10, DialogY + LAYER_DIALOG_HEIGHT - 15);
 If LayerDialogHighlightedButton = 3 Then
  SetColor(White)
 Else
  SetColor(PROP_DIALOG_TEXT);
 OutTextXY(DialogX + LAYER_DIALOG_WIDTH - 60, DialogY + LAYER_DIALOG_HEIGHT - 31, 'Close');
End;

{ ProcÃ©dure pour afficher la boÃ®te de dialogue des calques }
Procedure ShowLayerDialog;
Begin
 LayerDialogVisible := True;
 LayerDialogSelectedLayer := CurrentLayer;
 LayerDialogHighlightedButton := 0;
End;

{ ProcÃ©dure pour masquer la boÃ®te de dialogue des calques }
Procedure HideLayerDialog;
Begin
 LayerDialogVisible := False;
End;

{ ProcÃ©dure pour gÃ©rer un clic dans la boÃ®te de dialogue des calques }
Procedure HandleLayerDialogClick(X, Y: Integer);
Var
 I, ItemY: Integer;
 DialogX, DialogY: Integer;
Begin
 If Not LayerDialogVisible Then Exit;

 DialogX := LayerDialogX;
 DialogY := LayerDialogY;

 { VÃ©rifier clic sur les calques }
 For I := 1 to LayerCount do Begin
  ItemY := DialogY + 45 + (I - 1) * LAYER_ITEM_HEIGHT;

  If (Y >= ItemY - 2) and (Y < ItemY + LAYER_ITEM_HEIGHT - 4) Then Begin
   { Clic sur Visible (checkbox) }
   If (X >= DialogX + 5) and (X <= DialogX + 22) Then Begin
    Layers[I].Visible := Not Layers[I].Visible;
    DocumentModified := True;
    Exit;
   End;

   { Clic sur Locked (checkbox) }
   If (X >= DialogX + 25) and (X <= DialogX + 42) Then Begin
    Layers[I].Locked := Not Layers[I].Locked;
    DocumentModified := True;
    Exit;
   End;

   { Clic sur le nom pour sÃ©lectionner le calque }
   If (X >= DialogX + 50) and (X <= DialogX + LAYER_DIALOG_WIDTH - 10) Then Begin
    LayerDialogSelectedLayer := I;
    Exit;
   End;
  End;
 End;

 { VÃ©rifier clic sur le bouton New }
 If (X >= DialogX + 10) and (X <= DialogX + 70) and
    (Y >= DialogY + LAYER_DIALOG_HEIGHT - 35) and
    (Y <= DialogY + LAYER_DIALOG_HEIGHT - 15) Then Begin
  InsertLayer;
  LayerDialogSelectedLayer := LayerCount;
  Exit;
 End;

 { VÃ©rifier clic sur le bouton Set Active }
 If (X >= DialogX + 80) and (X <= DialogX + 140) and
    (Y >= DialogY + LAYER_DIALOG_HEIGHT - 35) and
    (Y <= DialogY + LAYER_DIALOG_HEIGHT - 15) Then Begin
  If (LayerDialogSelectedLayer >= 1) and (LayerDialogSelectedLayer <= LayerCount) Then Begin
   CurrentLayer := LayerDialogSelectedLayer;
  End;
  Exit;
 End;

 { VÃ©rifier clic sur le bouton Close }
 If (X >= DialogX + LAYER_DIALOG_WIDTH - 70) and
    (X <= DialogX + LAYER_DIALOG_WIDTH - 10) and
    (Y >= DialogY + LAYER_DIALOG_HEIGHT - 35) and
    (Y <= DialogY + LAYER_DIALOG_HEIGHT - 15) Then Begin
  HideLayerDialog;
  Exit;
 End;
End;

{ ProcÃ©dure pour gÃ©rer le survol dans la boÃ®te de dialogue des calques }
Procedure HandleLayerDialogHover(X, Y: Integer);
Var
 DialogX, DialogY: Integer;
 OldHighlight: Integer;
Begin
 If Not LayerDialogVisible Then Exit;

 DialogX := LayerDialogX;
 DialogY := LayerDialogY;
 OldHighlight := LayerDialogHighlightedButton;
 LayerDialogHighlightedButton := 0;

 { VÃ©rifier survol du bouton New }
 If (X >= DialogX + 10) and (X <= DialogX + 70) and
    (Y >= DialogY + LAYER_DIALOG_HEIGHT - 35) and
    (Y <= DialogY + LAYER_DIALOG_HEIGHT - 15) Then Begin
  LayerDialogHighlightedButton := 1;
 End
 { VÃ©rifier survol du bouton Set Active }
 Else If (X >= DialogX + 80) and (X <= DialogX + 140) and
         (Y >= DialogY + LAYER_DIALOG_HEIGHT - 35) and
         (Y <= DialogY + LAYER_DIALOG_HEIGHT - 15) Then Begin
  LayerDialogHighlightedButton := 2;
 End
 { VÃ©rifier survol du bouton Close }
 Else If (X >= DialogX + LAYER_DIALOG_WIDTH - 70) and
         (X <= DialogX + LAYER_DIALOG_WIDTH - 10) and
         (Y >= DialogY + LAYER_DIALOG_HEIGHT - 35) and
         (Y <= DialogY + LAYER_DIALOG_HEIGHT - 15) Then Begin
  LayerDialogHighlightedButton := 3;
 End;
End;

{ *** FIN BOÃŽTE DE DIALOGUE DES CALQUES *** }

{ ProcÃ©dure FormatFill - Modifier la couleur de remplissage }
Procedure FormatFill;
Begin
 { Afficher la boÃ®te de dialogue des propriÃ©tÃ©s pour modifier la couleur de remplissage }
 If HasSelection Then Begin
  ShowPropertiesDialog;
 End;
End;

{ ProcÃ©dure FormatLine - Modifier les propriÃ©tÃ©s de ligne }
Procedure FormatLine;
Begin
 { Afficher la boÃ®te de dialogue des propriÃ©tÃ©s pour modifier les propriÃ©tÃ©s de ligne }
 If HasSelection Then Begin
  ShowPropertiesDialog;
 End;
End;

{ ProcÃ©dure FormatText - Modifier les propriÃ©tÃ©s de texte }
Procedure FormatText;
Begin
 { TODO: Afficher une boÃ®te de dialogue pour choisir la police, taille et style de texte }
 { TODO: Appliquer les propriÃ©tÃ©s de texte aux objets texte sÃ©lectionnÃ©s }
 If HasSelection Then Begin
  DocumentModified := True;
 End;
End;

{ ProcÃ©dure FormatAlignment - Modifier l'alignement des objets }
Procedure FormatAlignment;
Begin
 { TODO: Afficher un sous-menu ou dialogue pour choisir le type d'alignement }
 { TODO: Aligner les objets sÃ©lectionnÃ©s selon le type choisi }
 If HasSelection Then Begin
  DocumentModified := True;
 End;
End;

{ ProcÃ©dure FormatArrange - Modifier l'ordre des objets }
Procedure FormatArrange;
Begin
 { TODO: Afficher un sous-menu pour choisir Bring to Front, Send to Back, etc. }
 { TODO: Modifier l'ordre Z des objets sÃ©lectionnÃ©s }
 If HasSelection Then Begin
  DocumentModified := True;
 End;
End;

{ Fonction pour compter le nombre d'objets sÃ©lectionnÃ©s }
Function CountSelectedShapes: Integer;
Var
 I, Count: Integer;
Begin
 Count := 0;
 For I := 1 to ShapeCount do Begin
  If Shapes[I].Selected Then
   Count := Count + 1;
 End;
 CountSelectedShapes := Count;
End;

{ ProcÃ©dure FormatGroup - Grouper les objets sÃ©lectionnÃ©s }
Procedure FormatGroup;
Var
 I: Integer;
 SelectedCount: Integer;
Begin
 SelectedCount := CountSelectedShapes;
 { On a besoin d'au moins 2 objets pour crÃ©er un groupe }
 If SelectedCount >= 2 Then Begin
  { IncrÃ©menter le compteur de groupe pour obtenir un nouvel ID }
  NextGroupID := NextGroupID + 1;
  { Assigner le mÃªme GroupID Ã  tous les objets sÃ©lectionnÃ©s }
  For I := 1 to ShapeCount do Begin
   If Shapes[I].Selected Then Begin
    Shapes[I].GroupID := NextGroupID;
   End;
  End;
  ObjectsGrouped := True;
  DocumentModified := True;
 End;
End;

{ ProcÃ©dure FormatUngroup - DÃ©grouper les objets }
Procedure FormatUngroup;
Var
 I: Integer;
 GroupToUngroup: Integer;
Begin
 If HasSelection Then Begin
  { Trouver le GroupID du premier objet sÃ©lectionnÃ© }
  GroupToUngroup := 0;
  For I := 1 to ShapeCount do Begin
   If Shapes[I].Selected And (Shapes[I].GroupID > 0) Then Begin
    GroupToUngroup := Shapes[I].GroupID;
    Break;
   End;
  End;
  { Si on a trouvÃ© un groupe, dÃ©grouper tous les objets de ce groupe }
  If GroupToUngroup > 0 Then Begin
   For I := 1 to ShapeCount do Begin
    If Shapes[I].GroupID = GroupToUngroup Then Begin
     Shapes[I].GroupID := 0;
     Shapes[I].Selected := True;  { SÃ©lectionner tous les objets du groupe }
    End;
   End;
   ObjectsGrouped := False;
   DocumentModified := True;
  End;
 End;
End;

{ ProcÃ©dure EnterGroup - Entrer dans un groupe pour Ã©diter ses objets }
Procedure EnterGroup;
Var
 I, J: Integer;
Begin
 If HasSelection Then Begin
  { Trouver le GroupID du premier objet sÃ©lectionnÃ© }
  For I := 1 to ShapeCount do Begin
   If Shapes[I].Selected And (Shapes[I].GroupID > 0) Then Begin
    EditingGroupID := Shapes[I].GroupID;
    { DÃ©sÃ©lectionner tout }
    For J := 1 to ShapeCount do
     Shapes[J].Selected := False;
    Exit;
   End;
  End;
 End;
End;

{ ProcÃ©dure ExitGroup - Sortir du mode Ã©dition de groupe }
Procedure ExitGroup;
Var
 I: Integer;
Begin
 If EditingGroupID > 0 Then Begin
  { SÃ©lectionner le groupe comme un tout }
  For I := 1 to ShapeCount do Begin
   If Shapes[I].GroupID = EditingGroupID Then Begin
    Shapes[I].Selected := True;
   End;
  End;
  EditingGroupID := 0;
 End;
End;

{ Fonction pour vÃ©rifier si une forme fait partie du groupe en cours d'Ã©dition }
Function IsShapeInEditingGroup(ShapeIndex: Integer): Boolean;
Begin
 If EditingGroupID = 0 Then
  IsShapeInEditingGroup := True  { Pas en mode Ã©dition de groupe, tout est accessible }
 Else
  IsShapeInEditingGroup := Shapes[ShapeIndex].GroupID = EditingGroupID;
End;

{ Fonction pour sÃ©lectionner tout le groupe quand on clique sur un membre }
Procedure SelectGroup(GroupID: Integer);
Var
 I: Integer;
Begin
 For I := 1 to ShapeCount do Begin
  If Shapes[I].GroupID = GroupID Then Begin
   Shapes[I].Selected := True;
  End;
 End;
End;

{ Fonction pour calculer le rectangle englobant d'un groupe }
Procedure GetGroupBounds(GroupID: Integer; Var MinX, MinY, MaxX, MaxY: Integer);
Var
 I: Integer;
 First: Boolean;
Begin
 First := True;
 MinX := 0; MinY := 0; MaxX := 0; MaxY := 0;
 For I := 1 to ShapeCount do Begin
  If Shapes[I].GroupID = GroupID Then Begin
   If First Then Begin
    MinX := Shapes[I].X1;
    MinY := Shapes[I].Y1;
    MaxX := Shapes[I].X2;
    MaxY := Shapes[I].Y2;
    First := False;
   End
   Else Begin
    If Shapes[I].X1 < MinX Then MinX := Shapes[I].X1;
    If Shapes[I].Y1 < MinY Then MinY := Shapes[I].Y1;
    If Shapes[I].X2 > MaxX Then MaxX := Shapes[I].X2;
    If Shapes[I].Y2 > MaxY Then MaxY := Shapes[I].Y2;
   End;
  End;
 End;
End;

{ ============================================================================ }
{ === FIN DES PROCEDURES DU MENU FORMAT === }
{ ============================================================================ }

{ ============================================================================ }
{ === PROCEDURES DU MENU SHAPE === }
{ ============================================================================ }

Type
 TRotationType = (rtRotate90CW, rtRotate90CCW, rtRotate180, rtFreeRotate);
 TFlipType = (ftHorizontal, ftVertical);
 TAlignShapeType = (asLeft, asCenter, asRight, asTop, asMiddle, asBottom);
 TDistributeType = (dtHorizontal, dtVertical);
 TOperationType = (otUnion, otIntersect, otSubtract);

Var
 CurrentRotation: Integer;  { Angle de rotation actuel en degrÃ©s }
 ShapeWidth: Integer;       { Largeur de la forme sÃ©lectionnÃ©e }
 ShapeHeight: Integer;      { Hauteur de la forme sÃ©lectionnÃ©e }
 ShapeX: Integer;           { Position X de la forme sÃ©lectionnÃ©e }
 ShapeY: Integer;           { Position Y de la forme sÃ©lectionnÃ©e }

{ ProcÃ©dure ShapeRotate - Rotation de la forme sÃ©lectionnÃ©e }
Procedure ShapeRotate;
Begin
 If HasSelection Then Begin
  { TODO: Afficher un sous-menu pour choisir l'angle de rotation }
  { TODO: Options: 90Â° horaire, 90Â° anti-horaire, 180Â°, rotation libre }
  CurrentRotation := (CurrentRotation + 90) Mod 360;
  DocumentModified := True;
 End;
End;

{ ProcÃ©dure ShapeFlip - Retourner la forme horizontalement ou verticalement }
Procedure ShapeFlip;
Begin
 If HasSelection Then Begin
  { TODO: Afficher un sous-menu pour choisir le type de retournement }
  { TODO: Options: Horizontal, Vertical }
  DocumentModified := True;
 End;
End;

{ ProcÃ©dure ShapeAlign - Aligner les formes sÃ©lectionnÃ©es }
Procedure ShapeAlign;
Begin
 If HasSelection Then Begin
  { TODO: Afficher un sous-menu pour choisir le type d'alignement }
  { TODO: Options: Left, Center, Right, Top, Middle, Bottom }
  DocumentModified := True;
 End;
End;

{ ProcÃ©dure ShapeDistribute - Distribuer les formes uniformÃ©ment }
Procedure ShapeDistribute;
Begin
 If HasSelection Then Begin
  { TODO: Afficher un sous-menu pour choisir la distribution }
  { TODO: Options: Horizontal, Vertical }
  { TODO: Espacer les formes uniformÃ©ment entre la premiÃ¨re et la derniÃ¨re }
  DocumentModified := True;
 End;
End;

{ ProcÃ©dure ShapeSize - Modifier la taille de la forme }
Procedure ShapeSize;
Begin
 If HasSelection Then Begin
  { TODO: Afficher une boÃ®te de dialogue pour entrer la nouvelle taille }
  { TODO: Permettre de spÃ©cifier largeur et hauteur en pixels ou pourcentage }
  DocumentModified := True;
 End;
End;

{ ProcÃ©dure ShapePosition - Modifier la position de la forme }
Procedure ShapePosition;
Begin
 If HasSelection Then Begin
  { TODO: Afficher une boÃ®te de dialogue pour entrer la nouvelle position }
  { TODO: Permettre de spÃ©cifier les coordonnÃ©es X et Y }
  DocumentModified := True;
 End;
End;

{ ProcÃ©dure ShapeOperations - OpÃ©rations boolÃ©ennes sur les formes }
Procedure ShapeOperations;
Begin
 If HasSelection Then Begin
  { TODO: Afficher un sous-menu pour choisir l'opÃ©ration }
  { TODO: Options: Union, Intersect, Subtract }
  { TODO: Union: Combiner plusieurs formes en une seule }
  { TODO: Intersect: Garder seulement la partie commune des formes }
  { TODO: Subtract: Soustraire une forme d'une autre }
  DocumentModified := True;
 End;
End;

{ ============================================================================ }
{ === FIN DES PROCEDURES DU MENU SHAPE === }
{ ============================================================================ }

{ ============================================================================ }
{ === PROCEDURES DE LA BARRE D'OUTILS === }
{ ============================================================================ }

{ ProcÃ©dure pour dessiner l'icÃ´ne d'un outil }
Procedure DrawToolIcon(X, Y: Integer; ToolIndex: Integer);
Var
 CenterX, CenterY: Integer;
Begin
 CenterX := X + TOOLBAR_BUTTON_SIZE div 2;
 CenterY := Y + TOOLBAR_BUTTON_SIZE div 2;

 SetColor(Black);
 Case ToolIndex of
  1: Begin { Selection - flÃ¨che }
      Line(CenterX - 6, CenterY - 6, CenterX - 6, CenterY + 6);
      Line(CenterX - 6, CenterY - 6, CenterX + 4, CenterY);
      Line(CenterX - 6, CenterY + 6, CenterX + 4, CenterY);
      Line(CenterX - 6, CenterY + 6, CenterX - 6, CenterY - 6);
     End;
  2: Begin { Rectangle }
      Rectangle(CenterX - 7, CenterY - 5, CenterX + 7, CenterY + 5);
     End;
  3: Begin { Ellipse }
      Ellipse(CenterX, CenterY, 0, 360, 7, 5);
     End;
  4: Begin { Line - ligne diagonale }
      Line(CenterX - 6, CenterY + 6, CenterX + 6, CenterY - 6);
     End;
  5: Begin { Connector - deux points avec ligne }
      Circle(CenterX - 6, CenterY, 2);
      Circle(CenterX + 6, CenterY, 2);
      Line(CenterX - 4, CenterY, CenterX + 4, CenterY);
     End;
  6: Begin { Text - lettre A }
      OutTextXY(CenterX - 4, CenterY - 4, 'A');
     End;
 End;
End;

{ ProcÃ©dure pour dessiner un bouton de la barre d'outils }
Procedure DrawToolButton(Index: Integer; IsSelected: Boolean);
Var
 X, Y: Integer;
Begin
 { Calculer la position du bouton (disposition verticale a gauche) }
 X := TOOLBAR_PADDING;
 Y := TOOLBAR_TOP + TOOLBAR_PADDING +
      (Index - 1) * (TOOLBAR_BUTTON_SIZE + TOOLBAR_PADDING);

 { Dessiner le fond du bouton }
 If IsSelected Then Begin
  SetFillStyle(SolidFill, TOOLBAR_BTN_SELECTED);
 End
 Else Begin
  SetFillStyle(SolidFill, TOOLBAR_BTN_COLOR);
 End;
 Bar(X, Y, X + TOOLBAR_BUTTON_SIZE, Y + TOOLBAR_BUTTON_SIZE);

 { Dessiner la bordure du bouton }
 If IsSelected Then Begin
  SetColor(White);
 End
 Else Begin
  SetColor(TOOLBAR_BTN_BORDER);
 End;
 Rectangle(X, Y, X + TOOLBAR_BUTTON_SIZE, Y + TOOLBAR_BUTTON_SIZE);

 { Dessiner l'icÃ´ne de l'outil }
 DrawToolIcon(X, Y, Index);
End;

{ ProcÃ©dure pour dessiner la barre d'outils complÃ¨te }
Procedure DrawToolbar;
Var
 I: Integer;
 ToolIndex: Integer;
Begin
 { Dessiner le fond de la barre d'outils (colonne verticale a gauche) }
 SetFillStyle(SolidFill, TOOLBAR_COLOR);
 Bar(0, TOOLBAR_TOP, TOOLBAR_WIDTH, ScreenHeight);

 { Dessiner une ligne de sÃ©paration a droite }
 SetColor(DarkGray);
 Line(TOOLBAR_WIDTH, TOOLBAR_TOP, TOOLBAR_WIDTH, ScreenHeight);

 { Dessiner chaque bouton d'outil }
 For I := 1 to TOOLBAR_COUNT do Begin
  ToolIndex := Ord(CurrentTool) + 1;
  DrawToolButton(I, I = ToolIndex);
 End;
End;

{ Fonction pour obtenir l'outil Ã  une position donnÃ©e }
Function GetToolAtPosition(MouseX, MouseY: Integer): Integer;
Var
 I, X, Y: Integer;
Begin
 GetToolAtPosition := 0;

 If (MouseX < 0) or (MouseX > TOOLBAR_WIDTH) or (MouseY < TOOLBAR_TOP) Then Exit;

 { Parcourir chaque bouton pour voir si la souris est dessus }
 For I := 1 to TOOLBAR_COUNT do Begin
  X := TOOLBAR_PADDING;
  Y := TOOLBAR_TOP + TOOLBAR_PADDING +
       (I - 1) * (TOOLBAR_BUTTON_SIZE + TOOLBAR_PADDING);

  If (MouseX >= X) and (MouseX <= X + TOOLBAR_BUTTON_SIZE) and
     (MouseY >= Y) and (MouseY <= Y + TOOLBAR_BUTTON_SIZE) Then Begin
   GetToolAtPosition := I;
   Exit;
  End;
 End;
End;

{ ProcÃ©dure pour sÃ©lectionner un outil }
Procedure SelectTool(ToolIndex: Integer);
Begin
 If (ToolIndex >= 1) and (ToolIndex <= TOOLBAR_COUNT) Then Begin
  CurrentTool := TToolType(ToolIndex - 1);
 End;
End;

{ ============================================================================ }
{ === FIN DES PROCEDURES DE LA BARRE D'OUTILS === }
{ ============================================================================ }

{ ============================================================================ }
{ === BARRE D'ICONES HORIZONTALE (Nouveau, Ouvrir, Enregistrer, ...) === }
{ ============================================================================ }

{ Indices logiques dans la barre d'icones (1..ICONBAR_COUNT).
  0 = aucun. Les separateurs ne sont pas cliquables. }
{ 1: Nouveau, 2: Ouvrir, 3: Enregistrer, 4: separateur,
  5: Imprimer, 6: separateur, 7: Annuler, 8: Retablir. }

Function IsIconBarSeparator(Index: Integer): Boolean;
Begin
 IsIconBarSeparator := (Index = 4) or (Index = 6);
End;

Function GetIconBarButtonX(Index: Integer): Integer;
Var
 I, X: Integer;
Begin
 X := TOOLBAR_WIDTH + 1 + ICONBAR_PADDING;
 For I := 1 to Index - 1 Do Begin
  If IsIconBarSeparator(I) Then
   X := X + 8
  Else
   X := X + ICONBAR_BUTTON_SIZE + ICONBAR_PADDING;
 End;
 GetIconBarButtonX := X;
End;

{ Dessiner les icones (formes simples, 16x16 centrees dans 20x20) }
Procedure DrawIconBarIcon(X, Y, Index: Integer);
Var
 CX, CY: Integer;
Begin
 CX := X + ICONBAR_BUTTON_SIZE Div 2;
 CY := Y + ICONBAR_BUTTON_SIZE Div 2;
 Case Index Of
  1: Begin { Nouveau : page blanche avec coin plie }
      SetFillStyle(SolidFill, White);
      Bar(X + 4, Y + 3, X + 14, Y + 16);
      SetColor(Black);
      Rectangle(X + 4, Y + 3, X + 14, Y + 16);
      Line(X + 11, Y + 3, X + 14, Y + 6);
      Line(X + 11, Y + 3, X + 11, Y + 6);
      Line(X + 11, Y + 6, X + 14, Y + 6);
     End;
  2: Begin { Ouvrir : dossier }
      SetColor(Black);
      SetFillStyle(SolidFill, Yellow);
      Bar(X + 3, Y + 7, X + 16, Y + 15);
      Rectangle(X + 3, Y + 7, X + 16, Y + 15);
      Line(X + 3, Y + 7, X + 6, Y + 5);
      Line(X + 6, Y + 5, X + 10, Y + 5);
      Line(X + 10, Y + 5, X + 11, Y + 7);
     End;
  3: Begin { Enregistrer : disquette }
      SetColor(Black);
      SetFillStyle(SolidFill, Blue);
      Bar(X + 3, Y + 3, X + 16, Y + 16);
      Rectangle(X + 3, Y + 3, X + 16, Y + 16);
      SetFillStyle(SolidFill, White);
      Bar(X + 5, Y + 10, X + 14, Y + 16);
      Rectangle(X + 5, Y + 10, X + 14, Y + 16);
      Bar(X + 6, Y + 3, X + 12, Y + 7);
     End;
  5: Begin { Imprimer : imprimante }
      SetColor(Black);
      SetFillStyle(SolidFill, LightGray);
      Bar(X + 3, Y + 7, X + 16, Y + 13);
      Rectangle(X + 3, Y + 7, X + 16, Y + 13);
      SetFillStyle(SolidFill, White);
      Bar(X + 5, Y + 3, X + 14, Y + 7);
      Rectangle(X + 5, Y + 3, X + 14, Y + 7);
      Bar(X + 5, Y + 12, X + 14, Y + 16);
      Rectangle(X + 5, Y + 12, X + 14, Y + 16);
     End;
  7: Begin { Annuler (Undo) : fleche courbe a gauche }
      SetColor(Blue);
      Arc(CX, CY + 2, 30, 150, 6);
      SetColor(Blue);
      Line(X + 4, Y + 8, X + 7, Y + 6);
      Line(X + 4, Y + 8, X + 7, Y + 11);
     End;
  8: Begin { Retablir (Redo) : fleche courbe a droite }
      SetColor(Blue);
      Arc(CX, CY + 2, 30, 150, 6);
      SetColor(Blue);
      Line(X + 16, Y + 8, X + 13, Y + 6);
      Line(X + 16, Y + 8, X + 13, Y + 11);
     End;
 End;
End;

Procedure DrawIconBarButton(Index: Integer; IsHovered: Boolean);
Var
 X, Y: Integer;
Begin
 If IsIconBarSeparator(Index) Then Begin
  X := GetIconBarButtonX(Index);
  Y := ICONBAR_TOP + 4;
  SetColor(DarkGray);
  Line(X + 3, Y, X + 3, Y + ICONBAR_BUTTON_SIZE - 8);
  SetColor(White);
  Line(X + 4, Y, X + 4, Y + ICONBAR_BUTTON_SIZE - 8);
  Exit;
 End;

 X := GetIconBarButtonX(Index);
 Y := ICONBAR_TOP + 2;

 { Fond du bouton }
 SetFillStyle(SolidFill, LightGray);
 Bar(X, Y, X + ICONBAR_BUTTON_SIZE - 1, Y + ICONBAR_BUTTON_SIZE - 1);

 If IsHovered Then Begin
  { Effet 3D enfonce }
  SetColor(DarkGray);
  Line(X, Y, X + ICONBAR_BUTTON_SIZE - 1, Y);
  Line(X, Y, X, Y + ICONBAR_BUTTON_SIZE - 1);
  SetColor(White);
  Line(X + ICONBAR_BUTTON_SIZE - 1, Y, X + ICONBAR_BUTTON_SIZE - 1, Y + ICONBAR_BUTTON_SIZE - 1);
  Line(X, Y + ICONBAR_BUTTON_SIZE - 1, X + ICONBAR_BUTTON_SIZE - 1, Y + ICONBAR_BUTTON_SIZE - 1);
 End
 Else Begin
  { Effet 3D releve }
  SetColor(White);
  Line(X, Y, X + ICONBAR_BUTTON_SIZE - 1, Y);
  Line(X, Y, X, Y + ICONBAR_BUTTON_SIZE - 1);
  SetColor(DarkGray);
  Line(X + ICONBAR_BUTTON_SIZE - 1, Y, X + ICONBAR_BUTTON_SIZE - 1, Y + ICONBAR_BUTTON_SIZE - 1);
  Line(X, Y + ICONBAR_BUTTON_SIZE - 1, X + ICONBAR_BUTTON_SIZE - 1, Y + ICONBAR_BUTTON_SIZE - 1);
 End;

 DrawIconBarIcon(X, Y, Index);
End;

Procedure DrawIconBar;
Var
 I: Integer;
Begin
 { Fond }
 SetFillStyle(SolidFill, ICONBAR_COLOR);
 Bar(0, ICONBAR_TOP, ScreenWidth, ICONBAR_TOP + ICONBAR_HEIGHT);
 { Ligne de separation en bas }
 SetColor(DarkGray);
 Line(0, ICONBAR_TOP + ICONBAR_HEIGHT, ScreenWidth, ICONBAR_TOP + ICONBAR_HEIGHT);

 For I := 1 to ICONBAR_COUNT Do
  DrawIconBarButton(I, False);
End;

Function GetIconBarButtonAtPosition(MouseX, MouseY: Integer): Integer;
Var
 I, X: Integer;
Begin
 GetIconBarButtonAtPosition := 0;
 If (MouseY < ICONBAR_TOP + 2) or
    (MouseY > ICONBAR_TOP + 2 + ICONBAR_BUTTON_SIZE) Then Exit;
 For I := 1 to ICONBAR_COUNT Do Begin
  If IsIconBarSeparator(I) Then Continue;
  X := GetIconBarButtonX(I);
  If (MouseX >= X) and (MouseX <= X + ICONBAR_BUTTON_SIZE) Then Begin
   GetIconBarButtonAtPosition := I;
   Exit;
  End;
 End;
End;

Procedure ExecuteIconBarAction(Index: Integer); Forward;

{ ============================================================================ }
{ === FIN DE LA BARRE D'ICONES === }
{ ============================================================================ }

{ ============================================================================ }
{ === PROCEDURES DE GESTION DES OBJETS ET CLIC SOURIS === }
{ ============================================================================ }

{ ProcÃ©dure pour initialiser un objet vide }
Procedure InitShape(Var Shape: TShapeObject);
Var
 I: Integer;
Begin
 Shape.ShapeType := stNone;
 Shape.X1 := 0;
 Shape.Y1 := 0;
 Shape.X2 := 0;
 Shape.Y2 := 0;
 Shape.FillColor := White;
 Shape.LineColor := Black;
 Shape.LineWidth := 1;
 Shape.LineStyle := LINESTYLE_SOLID;
 Shape.LayerIndex := CurrentLayer;  { Assigner au calque actif }
 Shape.GroupID := 0;                { Pas dans un groupe par dÃ©faut }
 Shape.Text := '';
 Shape.Selected := False;
 { Initialiser les champs pour polygones et courbes de BÃ©zier }
 Shape.PointCount := 0;
 For I := 1 to MAX_POLYGON_POINTS do Begin
  Shape.Points[I].X := 0;
  Shape.Points[I].Y := 0;
 End;
 { Initialiser le chemin d'image }
 Shape.ImagePath := '';
 { Initialiser les champs de connexion pour les connecteurs }
 Shape.ConnectStartShape := 0;
 Shape.ConnectEndShape := 0;
 Shape.ConnectStartAnchor := ANCHOR_NONE;
 Shape.ConnectEndAnchor := ANCHOR_NONE;
End;

{ *** FONCTIONS POUR LES CONNECTEURS ET POINTS D'ANCRAGE *** }

{ Fonction pour calculer les coordonnÃ©es d'un point d'ancrage sur une forme }
Procedure GetAnchorPoint(ShapeIndex: Integer; AnchorType: Integer; Var AX, AY: Integer);
Var
 CenterX, CenterY: Integer;
Begin
 If (ShapeIndex < 1) or (ShapeIndex > ShapeCount) Then Begin
  AX := 0;
  AY := 0;
  Exit;
 End;

 With Shapes[ShapeIndex] do Begin
  CenterX := (X1 + X2) div 2;
  CenterY := (Y1 + Y2) div 2;

  Case AnchorType of
   ANCHOR_TOP: Begin
    AX := CenterX;
    AY := Y1;
   End;
   ANCHOR_BOTTOM: Begin
    AX := CenterX;
    AY := Y2;
   End;
   ANCHOR_LEFT: Begin
    AX := X1;
    AY := CenterY;
   End;
   ANCHOR_RIGHT: Begin
    AX := X2;
    AY := CenterY;
   End;
   ANCHOR_CENTER: Begin
    AX := CenterX;
    AY := CenterY;
   End;
   Else Begin
    AX := CenterX;
    AY := CenterY;
   End;
  End;
 End;
End;

{ Fonction pour trouver la forme et le point d'ancrage le plus proche d'une position }
Function FindNearestAnchor(X, Y: Integer; Var FoundShape: Integer; Var FoundAnchor: Integer): Boolean;
Var
 I, AnchorType: Integer;
 AX, AY: Integer;
 Dist, MinDist: Real;
 IsConnectable: Boolean;
Begin
 FindNearestAnchor := False;
 FoundShape := 0;
 FoundAnchor := ANCHOR_NONE;
 MinDist := ANCHOR_SNAP_DISTANCE + 1;

 For I := 1 to ShapeCount do Begin
  { Ne pas se connecter Ã  soi-mÃªme ou Ã  d'autres connecteurs }
  IsConnectable := (Shapes[I].ShapeType <> stConnector) and
                   (Shapes[I].ShapeType <> stLine) and
                   (Shapes[I].ShapeType <> stText) and
                   (Shapes[I].ShapeType <> stNone);

  If IsConnectable Then Begin
   For AnchorType := ANCHOR_TOP to ANCHOR_RIGHT do Begin
    GetAnchorPoint(I, AnchorType, AX, AY);
    Dist := Sqrt(Sqr(X - AX) + Sqr(Y - AY));
    If Dist < MinDist Then Begin
     MinDist := Dist;
     FoundShape := I;
     FoundAnchor := AnchorType;
     FindNearestAnchor := True;
    End;
   End;
  End;
 End;
End;

{ ProcÃ©dure pour mettre Ã  jour les extrÃ©mitÃ©s d'un connecteur selon ses connexions }
Procedure UpdateConnectorEndpoints(ConnectorIndex: Integer);
Var
 AX, AY: Integer;
Begin
 If (ConnectorIndex < 1) or (ConnectorIndex > ShapeCount) Then Exit;
 If Shapes[ConnectorIndex].ShapeType <> stConnector Then Exit;

 With Shapes[ConnectorIndex] do Begin
  { Mettre Ã  jour le point de dÃ©part si connectÃ© }
  If ConnectStartShape > 0 Then Begin
   GetAnchorPoint(ConnectStartShape, ConnectStartAnchor, AX, AY);
   X1 := AX;
   Y1 := AY;
  End;

  { Mettre Ã  jour le point d'arrivÃ©e si connectÃ© }
  If ConnectEndShape > 0 Then Begin
   GetAnchorPoint(ConnectEndShape, ConnectEndAnchor, AX, AY);
   X2 := AX;
   Y2 := AY;
  End;
 End;
End;

{ ProcÃ©dure pour mettre Ã  jour tous les connecteurs (aprÃ¨s dÃ©placement d'une forme) }
Procedure UpdateAllConnectors;
Var
 I: Integer;
Begin
 For I := 1 to ShapeCount do Begin
  If Shapes[I].ShapeType = stConnector Then Begin
   UpdateConnectorEndpoints(I);
  End;
 End;
End;

{ ProcÃ©dure pour dessiner les points d'ancrage sur une forme }
Procedure DrawAnchorPoints(ShapeIndex: Integer; HighlightAnchor: Integer);
Var
 AnchorType: Integer;
 AX, AY: Integer;
 HalfSize: Integer;
 AnchorColor: Integer;
Begin
 If (ShapeIndex < 1) or (ShapeIndex > ShapeCount) Then Exit;

 { Ne pas dessiner les ancres sur les connecteurs, lignes ou textes }
 If Shapes[ShapeIndex].ShapeType in [stConnector, stLine, stText, stNone] Then Exit;

 HalfSize := ANCHOR_POINT_SIZE div 2;

 For AnchorType := ANCHOR_TOP to ANCHOR_RIGHT do Begin
  GetAnchorPoint(ShapeIndex, AnchorType, AX, AY);

  { Choisir la couleur selon si le point est survolÃ© }
  If AnchorType = HighlightAnchor Then
   AnchorColor := Green  { Vert pour le point survolÃ© }
  Else
   AnchorColor := Cyan;  { Cyan pour les autres points }

  { Dessiner un petit carrÃ© pour le point d'ancrage }
  SetFillStyle(SolidFill, AnchorColor);
  SetColor(Black);
  Bar(AX - HalfSize, AY - HalfSize, AX + HalfSize, AY + HalfSize);
  Rectangle(AX - HalfSize, AY - HalfSize, AX + HalfSize, AY + HalfSize);
 End;
End;

{ ProcÃ©dure pour dessiner une poignÃ©e de redimensionnement unique }
Procedure DrawSingleHandle(X, Y: Integer; HandleNum: Integer);
Var
 HalfSize: Integer;
 HandleColor: Integer;
Begin
 HalfSize := SELECTION_HANDLE_SIZE div 2;

 { Choisir la couleur selon si la poignÃ©e est survolÃ©e }
 If HandleNum = HoveredHandle Then
  HandleColor := HANDLE_HOVER_COLOR
 Else
  HandleColor := HANDLE_NORMAL_COLOR;

 { Dessiner la poignÃ©e }
 SetFillStyle(SolidFill, HandleColor);
 SetColor(HANDLE_BORDER_COLOR);
 Bar(X - HalfSize, Y - HalfSize, X + HalfSize, Y + HalfSize);
 Rectangle(X - HalfSize, Y - HalfSize, X + HalfSize, Y + HalfSize);
End;

{ ProcÃ©dure pour dessiner les 8 poignÃ©es de redimensionnement sur un objet sÃ©lectionnÃ© }
Procedure DrawResizeHandles(Var Shape: TShapeObject);
Var
 CenterX, CenterY: Integer;
Begin
 If Not Shape.Selected Then Exit;

 CenterX := (Shape.X1 + Shape.X2) div 2;
 CenterY := (Shape.Y1 + Shape.Y2) div 2;

 { Dessiner les 8 poignÃ©es de redimensionnement }
 { Coin nord-ouest (haut-gauche) }
 DrawSingleHandle(Shape.X1, Shape.Y1, RESIZE_HANDLE_NW);

 { Milieu nord (haut) }
 DrawSingleHandle(CenterX, Shape.Y1, RESIZE_HANDLE_N);

 { Coin nord-est (haut-droite) }
 DrawSingleHandle(Shape.X2, Shape.Y1, RESIZE_HANDLE_NE);

 { Milieu est (droite) }
 DrawSingleHandle(Shape.X2, CenterY, RESIZE_HANDLE_E);

 { Coin sud-est (bas-droite) }
 DrawSingleHandle(Shape.X2, Shape.Y2, RESIZE_HANDLE_SE);

 { Milieu sud (bas) }
 DrawSingleHandle(CenterX, Shape.Y2, RESIZE_HANDLE_S);

 { Coin sud-ouest (bas-gauche) }
 DrawSingleHandle(Shape.X1, Shape.Y2, RESIZE_HANDLE_SW);

 { Milieu ouest (gauche) }
 DrawSingleHandle(Shape.X1, CenterY, RESIZE_HANDLE_W);
End;

{ ProcÃ©dure pour dessiner un objet unique }
Procedure DrawShape(Var Shape: TShapeObject);
Var
 CenterX, CenterY, RadiusX, RadiusY: Integer;
 I: Integer;
 T, OneMinusT: Real;
 BezierX, BezierY, PrevX, PrevY: Integer;
 GraphLineStyle: Integer;
Begin
 If Shape.ShapeType = stNone Then Exit;

 { Convertir le style de ligne en constante Graph }
 Case Shape.LineStyle of
  LINESTYLE_SOLID: GraphLineStyle := SolidLn;
  LINESTYLE_DASHED: GraphLineStyle := DashedLn;
  LINESTYLE_DOTTED: GraphLineStyle := DottedLn;
  LINESTYLE_DASHDOT: GraphLineStyle := CenterLn;
  Else GraphLineStyle := SolidLn;
 End;

 { DÃ©finir la couleur de contour et le style de ligne }
 SetColor(Shape.LineColor);
 SetLineStyle(GraphLineStyle, 0, Shape.LineWidth);

 Case Shape.ShapeType of
  stRectangle: Begin
    { Remplir le rectangle }
    SetFillStyle(SolidFill, Shape.FillColor);
    Bar(Shape.X1, Shape.Y1, Shape.X2, Shape.Y2);
    { Dessiner le contour }
    SetColor(Shape.LineColor);
    Rectangle(Shape.X1, Shape.Y1, Shape.X2, Shape.Y2);
   End;
  stEllipse: Begin
    CenterX := (Shape.X1 + Shape.X2) div 2;
    CenterY := (Shape.Y1 + Shape.Y2) div 2;
    RadiusX := Abs(Shape.X2 - Shape.X1) div 2;
    RadiusY := Abs(Shape.Y2 - Shape.Y1) div 2;
    { Remplir l'ellipse }
    SetFillStyle(SolidFill, Shape.FillColor);
    FillEllipse(CenterX, CenterY, RadiusX, RadiusY);
    { Dessiner le contour }
    SetColor(Shape.LineColor);
    Ellipse(CenterX, CenterY, 0, 360, RadiusX, RadiusY);
   End;
  stLine: Begin
    SetColor(Shape.LineColor);
    Line(Shape.X1, Shape.Y1, Shape.X2, Shape.Y2);
   End;
  stConnector: Begin
    { Dessiner une ligne avec des cercles aux extrÃ©mitÃ©s }
    SetColor(Shape.LineColor);
    Line(Shape.X1, Shape.Y1, Shape.X2, Shape.Y2);

    { Dessiner le point de dÃ©part }
    If Shape.ConnectStartShape > 0 Then Begin
     { ConnectÃ© - dessiner un carrÃ© plein }
     SetFillStyle(SolidFill, Green);
     Bar(Shape.X1 - 4, Shape.Y1 - 4, Shape.X1 + 4, Shape.Y1 + 4);
     SetColor(Shape.LineColor);
     Rectangle(Shape.X1 - 4, Shape.Y1 - 4, Shape.X1 + 4, Shape.Y1 + 4);
    End
    Else Begin
     { Non connectÃ© - dessiner un cercle }
     SetFillStyle(SolidFill, Shape.FillColor);
     FillEllipse(Shape.X1, Shape.Y1, 4, 4);
     SetColor(Shape.LineColor);
     Circle(Shape.X1, Shape.Y1, 4);
    End;

    { Dessiner le point d'arrivÃ©e }
    If Shape.ConnectEndShape > 0 Then Begin
     { ConnectÃ© - dessiner un carrÃ© plein }
     SetFillStyle(SolidFill, Green);
     Bar(Shape.X2 - 4, Shape.Y2 - 4, Shape.X2 + 4, Shape.Y2 + 4);
     SetColor(Shape.LineColor);
     Rectangle(Shape.X2 - 4, Shape.Y2 - 4, Shape.X2 + 4, Shape.Y2 + 4);
    End
    Else Begin
     { Non connectÃ© - dessiner un cercle }
     SetFillStyle(SolidFill, Shape.FillColor);
     FillEllipse(Shape.X2, Shape.Y2, 4, 4);
     SetColor(Shape.LineColor);
     Circle(Shape.X2, Shape.Y2, 4);
    End;
   End;
  stText: Begin
    SetColor(Shape.LineColor);
    OutTextXY(Shape.X1, Shape.Y1, Shape.Text);
   End;
  stPolygon: Begin
    { Dessiner un polygone si au moins 3 points sont dÃ©finis }
    If Shape.PointCount >= 3 Then Begin
     { Remplir le polygone en dessinant des lignes de remplissage }
     SetFillStyle(SolidFill, Shape.FillColor);
     { Dessiner le contour du polygone }
     SetColor(Shape.LineColor);
     For I := 1 to Shape.PointCount - 1 do Begin
      Line(Shape.Points[I].X, Shape.Points[I].Y,
           Shape.Points[I + 1].X, Shape.Points[I + 1].Y);
     End;
     { Fermer le polygone }
     Line(Shape.Points[Shape.PointCount].X, Shape.Points[Shape.PointCount].Y,
          Shape.Points[1].X, Shape.Points[1].Y);
    End;
   End;
  stBezier: Begin
    { Dessiner une courbe de BÃ©zier cubique (4 points de contrÃ´le) }
    If Shape.PointCount = 4 Then Begin
     SetColor(Shape.LineColor);
     { Dessiner la courbe de BÃ©zier par approximation avec des segments de ligne }
     { P0 = Points[1], P1 = Points[2], P2 = Points[3], P3 = Points[4] }
     { Formule: B(t) = (1-t)^3*P0 + 3*(1-t)^2*t*P1 + 3*(1-t)*t^2*P2 + t^3*P3 }
     PrevX := Shape.Points[1].X;
     PrevY := Shape.Points[1].Y;
     For I := 1 to 20 do Begin
      T := I / 20;
      OneMinusT := 1 - T;
      { Calcul de la position sur la courbe }
      BezierX := Round(
       OneMinusT * OneMinusT * OneMinusT * Shape.Points[1].X +
       3 * OneMinusT * OneMinusT * T * Shape.Points[2].X +
       3 * OneMinusT * T * T * Shape.Points[3].X +
       T * T * T * Shape.Points[4].X
      );
      BezierY := Round(
       OneMinusT * OneMinusT * OneMinusT * Shape.Points[1].Y +
       3 * OneMinusT * OneMinusT * T * Shape.Points[2].Y +
       3 * OneMinusT * T * T * Shape.Points[3].Y +
       T * T * T * Shape.Points[4].Y
      );
      Line(PrevX, PrevY, BezierX, BezierY);
      PrevX := BezierX;
      PrevY := BezierY;
     End;
     { Dessiner les points de contrÃ´le si sÃ©lectionnÃ© }
     If Shape.Selected Then Begin
      SetColor(LightGray);
      Line(Shape.Points[1].X, Shape.Points[1].Y, Shape.Points[2].X, Shape.Points[2].Y);
      Line(Shape.Points[3].X, Shape.Points[3].Y, Shape.Points[4].X, Shape.Points[4].Y);
      SetFillStyle(SolidFill, Yellow);
      For I := 1 to 4 do Begin
       FillEllipse(Shape.Points[I].X, Shape.Points[I].Y, 3, 3);
      End;
     End;
    End;
   End;
  stImage: Begin
    { Dessiner un placeholder pour l'image (rectangle avec X) }
    SetFillStyle(SolidFill, Shape.FillColor);
    Bar(Shape.X1, Shape.Y1, Shape.X2, Shape.Y2);
    SetColor(Shape.LineColor);
    Rectangle(Shape.X1, Shape.Y1, Shape.X2, Shape.Y2);
    { Dessiner un X pour indiquer que c'est un placeholder d'image }
    Line(Shape.X1, Shape.Y1, Shape.X2, Shape.Y2);
    Line(Shape.X2, Shape.Y1, Shape.X1, Shape.Y2);
    { Afficher "Image" au centre }
    CenterX := (Shape.X1 + Shape.X2) div 2 - 20;
    CenterY := (Shape.Y1 + Shape.Y2) div 2 - 4;
    OutTextXY(CenterX, CenterY, 'Image');
   End;
 End;

 { Dessiner les 8 poignÃ©es de redimensionnement si l'objet est sÃ©lectionnÃ© }
 DrawResizeHandles(Shape);
End;

{ ProcÃ©dure pour dessiner tous les objets }
Procedure DrawAllShapes;
Var
 I: Integer;
Begin
 For I := 1 to ShapeCount do Begin
  { Ne dessiner que les formes des calques visibles }
  If IsLayerVisible(Shapes[I].LayerIndex) Then Begin
   DrawShape(Shapes[I]);
  End;
 End;

 { Dessiner les points d'ancrage sur la forme survolÃ©e si on utilise l'outil connecteur }
 If (CurrentTool = ttConnector) and (HoveredShapeForAnchor > 0) Then Begin
  DrawAnchorPoints(HoveredShapeForAnchor, NearestAnchorPoint);
 End;
End;

{ Fonction pour vÃ©rifier si un point est dans un objet }
Function PointInShape(X, Y: Integer; Var Shape: TShapeObject): Boolean;
Var
 MinX, MinY, MaxX, MaxY: Integer;
Begin
 PointInShape := False;
 If Shape.ShapeType = stNone Then Exit;

 { Normaliser les coordonnÃ©es }
 If Shape.X1 < Shape.X2 Then Begin
  MinX := Shape.X1;
  MaxX := Shape.X2;
 End
 Else Begin
  MinX := Shape.X2;
  MaxX := Shape.X1;
 End;

 If Shape.Y1 < Shape.Y2 Then Begin
  MinY := Shape.Y1;
  MaxY := Shape.Y2;
 End
 Else Begin
  MinY := Shape.Y2;
  MaxY := Shape.Y1;
 End;

 { VÃ©rifier si le point est dans le rectangle englobant }
 PointInShape := (X >= MinX) and (X <= MaxX) and (Y >= MinY) and (Y <= MaxY);
End;

{ Fonction pour trouver l'objet Ã  une position donnÃ©e }
Function GetShapeAtPosition(X, Y: Integer): Integer;
Var
 I: Integer;
Begin
 GetShapeAtPosition := 0;
 { Parcourir les objets du dernier au premier (prioritÃ© aux objets dessus) }
 For I := ShapeCount downto 1 do Begin
  { Ne sÃ©lectionner que les formes des calques visibles et non verrouillÃ©s }
  If IsLayerVisible(Shapes[I].LayerIndex) and
     (Not IsLayerLocked(Shapes[I].LayerIndex)) Then Begin
   { Si on est en mode Ã©dition de groupe, ne sÃ©lectionner que les objets du groupe }
   If IsShapeInEditingGroup(I) Then Begin
    If PointInShape(X, Y, Shapes[I]) Then Begin
     GetShapeAtPosition := I;
     Exit;
    End;
   End;
  End;
 End;
End;

{ ProcÃ©dure pour dÃ©sÃ©lectionner tous les objets }
Procedure DeselectAllShapes;
Var
 I: Integer;
Begin
 For I := 1 to ShapeCount do Begin
  Shapes[I].Selected := False;
 End;
 SelectedShape := 0;
End;

{ ProcÃ©dure pour sÃ©lectionner un objet }
Procedure SelectShape(Index: Integer);
Begin
 DeselectAllShapes;
 If (Index >= 1) and (Index <= ShapeCount) Then Begin
  { Si pas en mode Ã©dition de groupe et que l'objet fait partie d'un groupe, sÃ©lectionner tout le groupe }
  If (EditingGroupID = 0) and (Shapes[Index].GroupID > 0) Then Begin
   SelectGroup(Shapes[Index].GroupID);
   SelectedShape := Index;
  End
  Else Begin
   Shapes[Index].Selected := True;
   SelectedShape := Index;
  End;
 End;
End;

{ ============================================================================ }
{ === PROCEDURES POUR LE GLISSER-DEPOSER (DRAG AND DROP) === }
{ ============================================================================ }

{ Fonction pour dÃ©tecter quelle poignÃ©e de redimensionnement est sous le curseur }
Function GetResizeHandle(X, Y: Integer; ShapeIndex: Integer): Integer;
Var
 X1, Y1, X2, Y2: Integer;
 CenterX, CenterY: Integer;
 HalfSize: Integer;
Begin
 GetResizeHandle := RESIZE_HANDLE_NONE;

 If (ShapeIndex < 1) or (ShapeIndex > ShapeCount) Then Exit;
 If Not Shapes[ShapeIndex].Selected Then Exit;

 X1 := Shapes[ShapeIndex].X1;
 Y1 := Shapes[ShapeIndex].Y1;
 X2 := Shapes[ShapeIndex].X2;
 Y2 := Shapes[ShapeIndex].Y2;
 CenterX := (X1 + X2) div 2;
 CenterY := (Y1 + Y2) div 2;
 HalfSize := RESIZE_HANDLE_SIZE div 2;

 { VÃ©rifier chaque poignÃ©e }
 { Coin nord-ouest (haut-gauche) }
 If (Abs(X - X1) <= HalfSize) and (Abs(Y - Y1) <= HalfSize) Then Begin
  GetResizeHandle := RESIZE_HANDLE_NW;
  Exit;
 End;

 { Milieu nord (haut) }
 If (Abs(X - CenterX) <= HalfSize) and (Abs(Y - Y1) <= HalfSize) Then Begin
  GetResizeHandle := RESIZE_HANDLE_N;
  Exit;
 End;

 { Coin nord-est (haut-droite) }
 If (Abs(X - X2) <= HalfSize) and (Abs(Y - Y1) <= HalfSize) Then Begin
  GetResizeHandle := RESIZE_HANDLE_NE;
  Exit;
 End;

 { Milieu est (droite) }
 If (Abs(X - X2) <= HalfSize) and (Abs(Y - CenterY) <= HalfSize) Then Begin
  GetResizeHandle := RESIZE_HANDLE_E;
  Exit;
 End;

 { Coin sud-est (bas-droite) }
 If (Abs(X - X2) <= HalfSize) and (Abs(Y - Y2) <= HalfSize) Then Begin
  GetResizeHandle := RESIZE_HANDLE_SE;
  Exit;
 End;

 { Milieu sud (bas) }
 If (Abs(X - CenterX) <= HalfSize) and (Abs(Y - Y2) <= HalfSize) Then Begin
  GetResizeHandle := RESIZE_HANDLE_S;
  Exit;
 End;

 { Coin sud-ouest (bas-gauche) }
 If (Abs(X - X1) <= HalfSize) and (Abs(Y - Y2) <= HalfSize) Then Begin
  GetResizeHandle := RESIZE_HANDLE_SW;
  Exit;
 End;

 { Milieu ouest (gauche) }
 If (Abs(X - X1) <= HalfSize) and (Abs(Y - CenterY) <= HalfSize) Then Begin
  GetResizeHandle := RESIZE_HANDLE_W;
  Exit;
 End;
End;

{ ProcÃ©dure pour dÃ©placer un objet }
Procedure MoveShape(ShapeIndex: Integer; DeltaX, DeltaY: Integer);
Begin
 If (ShapeIndex < 1) or (ShapeIndex > ShapeCount) Then Exit;

 Shapes[ShapeIndex].X1 := Shapes[ShapeIndex].X1 + DeltaX;
 Shapes[ShapeIndex].Y1 := Shapes[ShapeIndex].Y1 + DeltaY;
 Shapes[ShapeIndex].X2 := Shapes[ShapeIndex].X2 + DeltaX;
 Shapes[ShapeIndex].Y2 := Shapes[ShapeIndex].Y2 + DeltaY;

 DocumentModified := True;
End;

{ ProcÃ©dure pour redimensionner un objet selon la poignÃ©e }
Procedure ResizeShape(ShapeIndex: Integer; Handle: Integer; NewX, NewY: Integer);
Begin
 If (ShapeIndex < 1) or (ShapeIndex > ShapeCount) Then Exit;

 Case Handle of
  RESIZE_HANDLE_NW: Begin
   Shapes[ShapeIndex].X1 := NewX;
   Shapes[ShapeIndex].Y1 := NewY;
  End;
  RESIZE_HANDLE_N: Begin
   Shapes[ShapeIndex].Y1 := NewY;
  End;
  RESIZE_HANDLE_NE: Begin
   Shapes[ShapeIndex].X2 := NewX;
   Shapes[ShapeIndex].Y1 := NewY;
  End;
  RESIZE_HANDLE_E: Begin
   Shapes[ShapeIndex].X2 := NewX;
  End;
  RESIZE_HANDLE_SE: Begin
   Shapes[ShapeIndex].X2 := NewX;
   Shapes[ShapeIndex].Y2 := NewY;
  End;
  RESIZE_HANDLE_S: Begin
   Shapes[ShapeIndex].Y2 := NewY;
  End;
  RESIZE_HANDLE_SW: Begin
   Shapes[ShapeIndex].X1 := NewX;
   Shapes[ShapeIndex].Y2 := NewY;
  End;
  RESIZE_HANDLE_W: Begin
   Shapes[ShapeIndex].X1 := NewX;
  End;
 End;

 DocumentModified := True;
End;

{ ProcÃ©dure pour dÃ©marrer le glissement }
Procedure StartDrag(ShapeIndex: Integer; X, Y: Integer; Handle: Integer);
Begin
 If (ShapeIndex < 1) or (ShapeIndex > ShapeCount) Then Exit;

 DragStartX := X;
 DragStartY := Y;
 DragOrigX1 := Shapes[ShapeIndex].X1;
 DragOrigY1 := Shapes[ShapeIndex].Y1;
 DragOrigX2 := Shapes[ShapeIndex].X2;
 DragOrigY2 := Shapes[ShapeIndex].Y2;

 If Handle <> RESIZE_HANDLE_NONE Then Begin
  { DÃ©marrer le redimensionnement }
  DragMode := DRAG_MODE_RESIZE;
  DragResizeHandle := Handle;
 End
 Else Begin
  { DÃ©marrer le dÃ©placement }
  DragMode := DRAG_MODE_MOVE;
  DragOffsetX := X - Shapes[ShapeIndex].X1;
  DragOffsetY := Y - Shapes[ShapeIndex].Y1;
  DragResizeHandle := RESIZE_HANDLE_NONE;
 End;
End;

{ ProcÃ©dure pour traiter le mouvement de la souris pendant le drag }
Procedure HandleMouseMove(X, Y: Integer);
Var
 DeltaX, DeltaY: Integer;
Begin
 If DragMode = DRAG_MODE_NONE Then Exit;
 If SelectedShape < 1 Then Exit;

 If DragMode = DRAG_MODE_MOVE Then Begin
  { DÃ©placer l'objet }
  DeltaX := X - DragStartX;
  DeltaY := Y - DragStartY;

  { Restaurer position originale puis appliquer le dÃ©placement }
  Shapes[SelectedShape].X1 := DragOrigX1 + DeltaX;
  Shapes[SelectedShape].Y1 := DragOrigY1 + DeltaY;
  Shapes[SelectedShape].X2 := DragOrigX2 + DeltaX;
  Shapes[SelectedShape].Y2 := DragOrigY2 + DeltaY;
 End
 Else If DragMode = DRAG_MODE_RESIZE Then Begin
  { Redimensionner l'objet }
  ResizeShape(SelectedShape, DragResizeHandle, X, Y);
 End;
End;

{ ProcÃ©dure pour terminer le glissement }
Procedure EndDrag;
Begin
 If DragMode <> DRAG_MODE_NONE Then Begin
  DocumentModified := True;
 End;
 DragMode := DRAG_MODE_NONE;
 DragResizeHandle := RESIZE_HANDLE_NONE;
End;

{ ProcÃ©dure pour initialiser le glisser-dÃ©poser }
Procedure InitDragDrop;
Begin
 DragMode := DRAG_MODE_NONE;
 DragStartX := 0;
 DragStartY := 0;
 DragOffsetX := 0;
 DragOffsetY := 0;
 DragResizeHandle := RESIZE_HANDLE_NONE;
 DragOrigX1 := 0;
 DragOrigY1 := 0;
 DragOrigX2 := 0;
 DragOrigY2 := 0;
 HoveredHandle := RESIZE_HANDLE_NONE;
End;

{ ============================================================================ }
{ === FIN DES PROCEDURES DE GLISSER-DEPOSER === }
{ ============================================================================ }

{ ============================================================================ }
{ === APERCU XOR (RUBBER-BAND) DE DESSIN DE FORME === }
{ ============================================================================ }

{ Trace une ellipse en XOR + DottedLn en l'approximant par une polyligne.
  Un second appel avec les memes parametres efface exactement le precedent. }
Procedure XorPreviewEllipse(CX, CY, RX, RY: Integer);
Const
 PiOver180 = 3.14159265358979 / 180.0;
Var
 I, N, Step: Integer;
 PX1, PY1, PX2, PY2: Integer;
 Theta: Real;
Begin
 If (RX <= 0) or (RY <= 0) Then Exit;
 N := (RX + RY) Div 2;
 If N < 16 Then N := 16;
 If N > 72 Then N := 72;
 Step := 360 Div N;
 If Step < 5 Then Step := 5;
 PX1 := CX + RX; PY1 := CY;
 I := Step;
 While I <= 360 Do Begin
  Theta := I * PiOver180;
  PX2 := CX + Round(RX * Cos(Theta));
  PY2 := CY + Round(RY * Sin(Theta));
  Line(PX1, PY1, PX2, PY2);
  PX1 := PX2; PY1 := PY2;
  Inc(I, Step);
 End;
 If (PX1 <> CX + RX) or (PY1 <> CY) Then
  Line(PX1, PY1, CX + RX, CY);
End;

{ Trace l'apercu d'une forme en XOR + pointilles. Un second appel identique
  efface le precedent. Supporte Rectangle, Ellipse, Ligne, Connecteur. }
Procedure XorPreviewShape(Tool: TToolType; X1, Y1, X2, Y2: Integer);
Var
 CX, CY, RX, RY: Integer;
Begin
 SetWriteMode(XORPut);
 SetColor(15); { Blanc }
 SetLineStyle(DottedLn, 0, NormWidth);
 Case Tool of
  ttRectangle: Rectangle(X1, Y1, X2, Y2);
  ttEllipse: Begin
   CX := (X1 + X2) Div 2;
   CY := (Y1 + Y2) Div 2;
   RX := Abs(X2 - X1) Div 2;
   RY := Abs(Y2 - Y1) Div 2;
   XorPreviewEllipse(CX, CY, RX, RY);
  End;
  ttLine, ttConnector: Line(X1, Y1, X2, Y2);
 End;
 SetLineStyle(SolidLn, 0, NormWidth);
 SetWriteMode(CopyPut);
End;

{ Efface l'apercu en cours (s'il est visible) et reinitialise l'etat. }
Procedure ClearPreview;
Begin
 If PreviewValid And PreviewVisible Then
  XorPreviewShape(PreviewTool, PreviewX1, PreviewY1, PreviewX2, PreviewY2);
 PreviewValid := False;
 PreviewVisible := False;
End;

{ Met a jour l'apercu pour la position courante de la souris. Efface l'ancien
  rectangle XOR (s'il existe) puis dessine le nouveau. }
Procedure UpdatePreview(Tool: TToolType; X1, Y1, X2, Y2: Integer);
Begin
 If PreviewValid And PreviewVisible Then
  XorPreviewShape(PreviewTool, PreviewX1, PreviewY1, PreviewX2, PreviewY2);
 PreviewTool := Tool;
 PreviewX1 := X1; PreviewY1 := Y1;
 PreviewX2 := X2; PreviewY2 := Y2;
 XorPreviewShape(PreviewTool, PreviewX1, PreviewY1, PreviewX2, PreviewY2);
 PreviewValid := True;
 PreviewVisible := True;
End;

{ Fait clignoter l'apercu : toggle son etat visible/invisible aux memes coords. }
Procedure BlinkPreview;
Begin
 If Not PreviewValid Then Exit;
 XorPreviewShape(PreviewTool, PreviewX1, PreviewY1, PreviewX2, PreviewY2);
 PreviewVisible := Not PreviewVisible;
End;

{ ============================================================================ }
{ === FIN APERCU XOR === }
{ ============================================================================ }

{ ProcÃ©dure pour ajouter un nouvel objet }
Procedure AddShape(ShapeType: TShapeType; X1, Y1, X2, Y2: Integer);
Var
 Temp: Integer;
Begin
 If ShapeCount >= MAX_SHAPES Then Exit;

 Inc(ShapeCount);
 InitShape(Shapes[ShapeCount]);
 Shapes[ShapeCount].ShapeType := ShapeType;

 { Normaliser les coordonnÃ©es (X1,Y1 = coin supÃ©rieur gauche) }
 If X1 > X2 Then Begin
  Temp := X1;
  X1 := X2;
  X2 := Temp;
 End;
 If Y1 > Y2 Then Begin
  Temp := Y1;
  Y1 := Y2;
  Y2 := Temp;
 End;

 Shapes[ShapeCount].X1 := X1;
 Shapes[ShapeCount].Y1 := Y1;
 Shapes[ShapeCount].X2 := X2;
 Shapes[ShapeCount].Y2 := Y2;
 Shapes[ShapeCount].FillColor := CurrentFillColor;
 Shapes[ShapeCount].LineColor := CurrentLineColor;
 Shapes[ShapeCount].LineWidth := CurrentLineWidth;
 Shapes[ShapeCount].LineStyle := CurrentLineStyle;

 DocumentModified := True;
End;

{ Forward decls : les dispatchers sont définis plus bas dans le fichier }
Function ExecuteFileMenuAction(ItemIndex: Integer): Boolean; Forward;
Procedure ExecuteEditMenuAction(ItemIndex: Integer); Forward;
Procedure ExecuteViewMenuAction(ItemIndex: Integer); Forward;
Procedure ExecuteInsertMenuAction(ItemIndex: Integer); Forward;
Procedure ExecuteFormatMenuAction(ItemIndex: Integer); Forward;
Procedure ExecuteShapeMenuAction(ItemIndex: Integer); Forward;
Function GetMenuAtPosition(MouseX, MouseY: Integer): Integer; Forward;
Function GetDropDownItemAtPosition(MenuIndex, MouseX, MouseY: Integer): Integer; Forward;

{ ProcÃ©dure pour gÃ©rer le clic gauche de la souris }
Procedure HandleLeftClick(X, Y: Integer);
Var
 ShapeIndex: Integer;
 ToolIndex: Integer;
 ResizeHandle: Integer;
 MenuIdx, ItemIdx: Integer;
 ShouldExit: Boolean;
Begin
 { Si un menu déroulant est ouvert, traiter d'abord la sélection d'un item }
 If (MenuState = msDropDown) and (CurrentMenu > 0) Then Begin
  ItemIdx := GetDropDownItemAtPosition(CurrentMenu, X, Y);
  If ItemIdx > 0 Then Begin
   { Dispatcher selon le menu actif }
   Case CurrentMenu of
    1: Begin
        ShouldExit := ExecuteFileMenuAction(ItemIdx);
        If ShouldExit Then Halt;
       End;
    2: ExecuteEditMenuAction(ItemIdx);
    3: ExecuteViewMenuAction(ItemIdx);
    4: ExecuteInsertMenuAction(ItemIdx);
    5: ExecuteFormatMenuAction(ItemIdx);
    6: ExecuteShapeMenuAction(ItemIdx);
    { Tools/Window/Help : pas de dispatcher implémenté }
   End;
   { Fermer le menu après l'action }
   MenuState := msNone;
   CurrentMenu := 0;
   Exit;
  End Else Begin
   { Clic en dehors de la liste : si on a cliqué sur un autre titre de
     menu dans la barre, basculer vers ce menu, sinon fermer. }
   MenuIdx := GetMenuAtPosition(X, Y);
   If MenuIdx > 0 Then Begin
    CurrentMenu := MenuIdx;
    MenuState := msDropDown;
    Exit;
   End;
   MenuState := msNone;
   CurrentMenu := 0;
   Exit;
  End;
 End;

 { Vérifier si le clic est dans la barre de menu : ouvrir le déroulant }
 If Y <= MENU_HEIGHT Then Begin
  MenuIdx := GetMenuAtPosition(X, Y);
  If MenuIdx > 0 Then Begin
   CurrentMenu := MenuIdx;
   MenuState := msDropDown;
  End;
  Exit;
 End;

 { Vérifier si le clic est dans la barre d'outils (colonne gauche) }
 If (Y > MENU_HEIGHT) and (Y >= TOOLBAR_TOP) and (X <= TOOLBAR_WIDTH) Then Begin
  ToolIndex := GetToolAtPosition(X, Y);
  If ToolIndex > 0 Then Begin
   SelectTool(ToolIndex);
   DrawToolbar;
  End;
  Exit;
 End;

 { Verifier si le clic est dans la barre d'icones horizontale }
 If (Y > MENU_HEIGHT) and (Y <= ICONBAR_TOP + ICONBAR_HEIGHT) and
    (X > TOOLBAR_WIDTH) Then Begin
  ToolIndex := GetIconBarButtonAtPosition(X, Y);
  If ToolIndex > 0 Then Begin
   { Effet d'enfoncement visuel bref }
   HideMouse;
   DrawIconBarButton(ToolIndex, True);
   ShowMouse;
   ExecuteIconBarAction(ToolIndex);
   RefreshScreen;
  End;
  Exit;
 End;

 { Le clic est dans la zone de travail }
 If Y > WORK_AREA_TOP Then Begin
  Case CurrentTool of
   ttSelection: Begin
     { Mode sÃ©lection: vÃ©rifier d'abord si on clique sur une poignÃ©e de redimensionnement }
     If SelectedShape > 0 Then Begin
      ResizeHandle := GetResizeHandle(X, Y, SelectedShape);
      If ResizeHandle <> RESIZE_HANDLE_NONE Then Begin
       { DÃ©marrer le redimensionnement }
       StartDrag(SelectedShape, X, Y, ResizeHandle);
       Exit;
      End;
     End;

     { Chercher un objet sous le curseur }
     ShapeIndex := GetShapeAtPosition(X, Y);
     If ShapeIndex > 0 Then Begin
      SelectShape(ShapeIndex);
      { DÃ©marrer le glissement pour dÃ©placer l'objet }
      StartDrag(ShapeIndex, X, Y, RESIZE_HANDLE_NONE);
     End
     Else Begin
      DeselectAllShapes;
      EndDrag;
     End;
    End;
   ttRectangle, ttEllipse, ttLine, ttConnector: Begin
     { DÃ©marrer le dessin d'une forme }
     IsDrawing := True;
     DrawStartX := X;
     DrawStartY := Y;
    End;
   ttText: Begin
     { Ajouter un objet texte Ã  la position du clic }
     If ShapeCount < MAX_SHAPES Then Begin
      Inc(ShapeCount);
      InitShape(Shapes[ShapeCount]);
      Shapes[ShapeCount].ShapeType := stText;
      Shapes[ShapeCount].X1 := X;
      Shapes[ShapeCount].Y1 := Y;
      Shapes[ShapeCount].X2 := X + 50;
      Shapes[ShapeCount].Y2 := Y + 12;
      Shapes[ShapeCount].Text := 'Text';
      Shapes[ShapeCount].LineColor := CurrentLineColor;
      DocumentModified := True;
     End;
    End;
   ttPolygon: Begin
     { Pour les polygones, on ajoute un point au polygone en cours }
     { Pour simplifier, crÃ©er un polygone rÃ©gulier (hexagone) }
     If ShapeCount < MAX_SHAPES Then Begin
      Inc(ShapeCount);
      InitShape(Shapes[ShapeCount]);
      Shapes[ShapeCount].ShapeType := stPolygon;
      { CrÃ©er un hexagone centrÃ© sur le clic }
      Shapes[ShapeCount].PointCount := 6;
      Shapes[ShapeCount].Points[1].X := X;
      Shapes[ShapeCount].Points[1].Y := Y - 30;
      Shapes[ShapeCount].Points[2].X := X + 26;
      Shapes[ShapeCount].Points[2].Y := Y - 15;
      Shapes[ShapeCount].Points[3].X := X + 26;
      Shapes[ShapeCount].Points[3].Y := Y + 15;
      Shapes[ShapeCount].Points[4].X := X;
      Shapes[ShapeCount].Points[4].Y := Y + 30;
      Shapes[ShapeCount].Points[5].X := X - 26;
      Shapes[ShapeCount].Points[5].Y := Y + 15;
      Shapes[ShapeCount].Points[6].X := X - 26;
      Shapes[ShapeCount].Points[6].Y := Y - 15;
      { Calculer le rectangle englobant }
      Shapes[ShapeCount].X1 := X - 26;
      Shapes[ShapeCount].Y1 := Y - 30;
      Shapes[ShapeCount].X2 := X + 26;
      Shapes[ShapeCount].Y2 := Y + 30;
      Shapes[ShapeCount].FillColor := CurrentFillColor;
      Shapes[ShapeCount].LineColor := CurrentLineColor;
      DocumentModified := True;
     End;
    End;
   ttBezier: Begin
     { CrÃ©er une courbe de BÃ©zier par dÃ©faut }
     If ShapeCount < MAX_SHAPES Then Begin
      Inc(ShapeCount);
      InitShape(Shapes[ShapeCount]);
      Shapes[ShapeCount].ShapeType := stBezier;
      { DÃ©finir 4 points de contrÃ´le pour une courbe de BÃ©zier cubique }
      Shapes[ShapeCount].PointCount := 4;
      Shapes[ShapeCount].Points[1].X := X;
      Shapes[ShapeCount].Points[1].Y := Y;
      Shapes[ShapeCount].Points[2].X := X + 30;
      Shapes[ShapeCount].Points[2].Y := Y - 40;
      Shapes[ShapeCount].Points[3].X := X + 70;
      Shapes[ShapeCount].Points[3].Y := Y - 40;
      Shapes[ShapeCount].Points[4].X := X + 100;
      Shapes[ShapeCount].Points[4].Y := Y;
      { Calculer le rectangle englobant }
      Shapes[ShapeCount].X1 := X;
      Shapes[ShapeCount].Y1 := Y - 40;
      Shapes[ShapeCount].X2 := X + 100;
      Shapes[ShapeCount].Y2 := Y;
      Shapes[ShapeCount].LineColor := CurrentLineColor;
      DocumentModified := True;
     End;
    End;
   ttImage: Begin
     { Ajouter un placeholder d'image }
     If ShapeCount < MAX_SHAPES Then Begin
      Inc(ShapeCount);
      InitShape(Shapes[ShapeCount]);
      Shapes[ShapeCount].ShapeType := stImage;
      Shapes[ShapeCount].X1 := X;
      Shapes[ShapeCount].Y1 := Y;
      Shapes[ShapeCount].X2 := X + 80;
      Shapes[ShapeCount].Y2 := Y + 60;
      Shapes[ShapeCount].FillColor := LightGray;
      Shapes[ShapeCount].LineColor := CurrentLineColor;
      Shapes[ShapeCount].ImagePath := '';
      DocumentModified := True;
     End;
    End;
  End;
 End;
End;

{ ProcÃ©dure pour gÃ©rer le relÃ¢chement du bouton gauche }
Procedure HandleLeftRelease(X, Y: Integer);
Var
 ShapeType: TShapeType;
 StartShape, StartAnchor: Integer;
 EndShape, EndAnchor: Integer;
Begin
 { Terminer le glissement s'il y en a un en cours }
 If DragMode <> DRAG_MODE_NONE Then Begin
  EndDrag;
  { Mettre Ã  jour tous les connecteurs aprÃ¨s dÃ©placement }
  UpdateAllConnectors;
  Exit;
 End;

 If Not IsDrawing Then Exit;

 IsDrawing := False;

 { Traitement spÃ©cial pour les connecteurs }
 If CurrentTool = ttConnector Then Begin
  { VÃ©rifier si on doit crÃ©er un connecteur }
  If (Abs(X - DrawStartX) > 5) or (Abs(Y - DrawStartY) > 5) Then Begin
   { Chercher les points d'ancrage proches pour le dÃ©but et la fin }
   FindNearestAnchor(DrawStartX, DrawStartY, StartShape, StartAnchor);
   FindNearestAnchor(X, Y, EndShape, EndAnchor);

   { CrÃ©er le connecteur }
   If ShapeCount < MAX_SHAPES Then Begin
    Inc(ShapeCount);
    InitShape(Shapes[ShapeCount]);
    Shapes[ShapeCount].ShapeType := stConnector;

    { DÃ©finir les connexions }
    Shapes[ShapeCount].ConnectStartShape := StartShape;
    Shapes[ShapeCount].ConnectStartAnchor := StartAnchor;
    Shapes[ShapeCount].ConnectEndShape := EndShape;
    Shapes[ShapeCount].ConnectEndAnchor := EndAnchor;

    { DÃ©finir les coordonnÃ©es initiales }
    Shapes[ShapeCount].X1 := DrawStartX;
    Shapes[ShapeCount].Y1 := DrawStartY;
    Shapes[ShapeCount].X2 := X;
    Shapes[ShapeCount].Y2 := Y;

    { Mettre Ã  jour les extrÃ©mitÃ©s si connectÃ© Ã  des formes }
    UpdateConnectorEndpoints(ShapeCount);

    Shapes[ShapeCount].FillColor := CurrentFillColor;
    Shapes[ShapeCount].LineColor := CurrentLineColor;
    Shapes[ShapeCount].LineWidth := CurrentLineWidth;
    DocumentModified := True;
   End;
  End;
  Exit;
 End;

 { CrÃ©er la forme selon l'outil actuel }
 Case CurrentTool of
  ttRectangle: ShapeType := stRectangle;
  ttEllipse: ShapeType := stEllipse;
  ttLine: ShapeType := stLine;
  ttImage: ShapeType := stImage;
  Else Exit;
 End;

 { Ajouter la forme si elle a une taille minimale }
 If (Abs(X - DrawStartX) > 5) or (Abs(Y - DrawStartY) > 5) Then Begin
  AddShape(ShapeType, DrawStartX, DrawStartY, X, Y);
 End;
End;

{ ProcÃ©dure pour initialiser les objets }
Procedure InitShapes;
Var
 I: Integer;
Begin
 ShapeCount := 0;
 SelectedShape := 0;
 IsDrawing := False;
 DrawStartX := 0;
 DrawStartY := 0;
 LastMouseX := 0;
 LastMouseY := 0;
 LastMouseButton := 0;
 PreviewValid := False;
 PreviewVisible := False;
 PreviewBlinkTick := 0;
 { Initialiser le glisser-dÃ©poser }
 InitDragDrop;
 { Initialiser les variables pour les points d'ancrage }
 HoveredShapeForAnchor := 0;
 NearestAnchorPoint := ANCHOR_NONE;
 { Initialiser les calques }
 InitAllLayers;
 { Initialiser les variables de la boÃ®te de dialogue des calques }
 LayerDialogVisible := False;
 LayerDialogX := 0;
 LayerDialogY := 0;
 LayerDialogSelectedLayer := 1;
 LayerDialogHighlightedButton := 0;
 For I := 1 to MAX_SHAPES do Begin
  InitShape(Shapes[I]);
 End;
End;

{ ============================================================================ }
{ === FIN DES PROCEDURES DE GESTION DES OBJETS === }
{ ============================================================================ }

{ ============================================================================ }
{ === PROCEDURES DU MENU CONTEXTUEL (CLIC DROIT) === }
{ ============================================================================ }

{ ProcÃ©dure pour masquer le menu contextuel }
Procedure HideContextMenu;
Begin
 ContextMenuVisible := False;
 ContextMenuHighlight := 0;
End;

{ ProcÃ©dure pour dessiner le menu contextuel }
Procedure DrawContextMenu;
Var
 I: Integer;
 MenuHeight: Integer;
 ItemY: Integer;
 ItemEnabled: Boolean;
Begin
 If Not ContextMenuVisible Then Exit;

 MenuHeight := CONTEXT_MENU_ITEM_COUNT * CONTEXT_MENU_ITEM_HEIGHT + 4;

 { Dessiner le fond du menu }
 SetFillStyle(SolidFill, CONTEXT_MENU_BG_COLOR);
 Bar(ContextMenuX, ContextMenuY, ContextMenuX + CONTEXT_MENU_WIDTH, ContextMenuY + MenuHeight);

 { Dessiner la bordure du menu }
 SetColor(CONTEXT_MENU_BORDER_COLOR);
 Rectangle(ContextMenuX, ContextMenuY, ContextMenuX + CONTEXT_MENU_WIDTH, ContextMenuY + MenuHeight);

 { Dessiner chaque Ã©lÃ©ment du menu }
 For I := 1 to CONTEXT_MENU_ITEM_COUNT do Begin
  ItemY := ContextMenuY + 2 + (I - 1) * CONTEXT_MENU_ITEM_HEIGHT;

  { DÃ©terminer si l'Ã©lÃ©ment est activÃ© }
  { Cut, Copy, Delete nÃ©cessitent une sÃ©lection }
  { Paste nÃ©cessite que le presse-papiers ne soit pas vide }
  { Properties nÃ©cessite une sÃ©lection }
  Case I of
   1: ItemEnabled := (SelectedShape > 0); { Cut }
   2: ItemEnabled := (SelectedShape > 0); { Copy }
   3: ItemEnabled := Not ClipboardEmpty;  { Paste }
   4: ItemEnabled := (SelectedShape > 0); { Delete }
   5: ItemEnabled := (SelectedShape > 0); { Properties }
   Else ItemEnabled := True;
  End;

  { Dessiner le fond de l'Ã©lÃ©ment si surbrillance }
  If (I = ContextMenuHighlight) and ItemEnabled Then Begin
   SetFillStyle(SolidFill, CONTEXT_MENU_HIGHLIGHT_BG);
   Bar(ContextMenuX + 1, ItemY, ContextMenuX + CONTEXT_MENU_WIDTH - 1, ItemY + CONTEXT_MENU_ITEM_HEIGHT);
   SetColor(CONTEXT_MENU_HIGHLIGHT_FG);
  End
  Else If ItemEnabled Then Begin
   SetColor(CONTEXT_MENU_TEXT_COLOR);
  End
  Else Begin
   SetColor(CONTEXT_MENU_DISABLED_COLOR);
  End;

  { Afficher le texte de l'Ã©lÃ©ment }
  OutTextXY(ContextMenuX + 8, ItemY + 4, ContextMenuNames[I]);
 End;
End;

{ Fonction pour obtenir l'Ã©lÃ©ment du menu contextuel Ã  une position }
Function GetContextMenuItemAtPosition(X, Y: Integer): Integer;
Var
 MenuHeight: Integer;
 RelY: Integer;
 Item: Integer;
Begin
 GetContextMenuItemAtPosition := 0;

 If Not ContextMenuVisible Then Exit;

 MenuHeight := CONTEXT_MENU_ITEM_COUNT * CONTEXT_MENU_ITEM_HEIGHT + 4;

 { VÃ©rifier si le point est dans le menu }
 If (X >= ContextMenuX) and (X <= ContextMenuX + CONTEXT_MENU_WIDTH) and
    (Y >= ContextMenuY) and (Y <= ContextMenuY + MenuHeight) Then Begin
  RelY := Y - ContextMenuY - 2;
  Item := (RelY div CONTEXT_MENU_ITEM_HEIGHT) + 1;
  If (Item >= 1) and (Item <= CONTEXT_MENU_ITEM_COUNT) Then Begin
   GetContextMenuItemAtPosition := Item;
  End;
 End;
End;

{ ProcÃ©dure pour exÃ©cuter une action du menu contextuel }
Procedure ExecuteContextMenuAction(ItemIndex: Integer);
Var
 ItemEnabled: Boolean;
Begin
 { VÃ©rifier si l'Ã©lÃ©ment est activÃ© }
 Case ItemIndex of
  1: ItemEnabled := (SelectedShape > 0); { Cut }
  2: ItemEnabled := (SelectedShape > 0); { Copy }
  3: ItemEnabled := Not ClipboardEmpty;  { Paste }
  4: ItemEnabled := (SelectedShape > 0); { Delete }
  5: ItemEnabled := (SelectedShape > 0); { Properties }
  Else ItemEnabled := False;
 End;

 If Not ItemEnabled Then Exit;

 Case ItemIndex of
  1: EditCut;        { Cut }
  2: EditCopy;       { Copy }
  3: EditPaste;      { Paste }
  4: EditDelete;     { Delete }
  5: ShowPropertiesDialog; { Properties - Afficher la boÃ®te de dialogue des propriÃ©tÃ©s }
 End;

 HideContextMenu;
End;

{ ProcÃ©dure pour afficher le menu contextuel }
Procedure ShowContextMenu(X, Y: Integer);
Begin
 { Ajuster la position pour que le menu reste visible }
 ContextMenuX := X;
 ContextMenuY := Y;

 { S'assurer que le menu ne dÃ©passe pas de l'Ã©cran }
 If ContextMenuX + CONTEXT_MENU_WIDTH > ScreenWidth Then Begin
  ContextMenuX := ScreenWidth - CONTEXT_MENU_WIDTH - 2;
 End;
 If ContextMenuY + (CONTEXT_MENU_ITEM_COUNT * CONTEXT_MENU_ITEM_HEIGHT + 4) > ScreenHeight Then Begin
  ContextMenuY := ScreenHeight - (CONTEXT_MENU_ITEM_COUNT * CONTEXT_MENU_ITEM_HEIGHT + 4) - 2;
 End;

 ContextMenuVisible := True;
 ContextMenuHighlight := 0;
End;

{ ProcÃ©dure pour gÃ©rer le clic droit de la souris }
Procedure HandleRightClick(X, Y: Integer);
Var
 ShapeIndex: Integer;
Begin
 { Masquer le menu contextuel s'il est dÃ©jÃ  visible }
 If ContextMenuVisible Then Begin
  HideContextMenu;
  Exit;
 End;

 { VÃ©rifier si le clic est dans la zone de travail }
 If Y > WORK_AREA_TOP Then Begin
  { Chercher s'il y a un objet sous le curseur }
  ShapeIndex := GetShapeAtPosition(X, Y);

  { Si un objet est trouvÃ©, le sÃ©lectionner }
  If ShapeIndex > 0 Then Begin
   SelectShape(ShapeIndex);
  End;

  { Afficher le menu contextuel }
  ShowContextMenu(X, Y);
 End;
End;

{ ProcÃ©dure pour initialiser le menu contextuel }
Procedure InitContextMenu;
Begin
 ContextMenuVisible := False;
 ContextMenuX := 0;
 ContextMenuY := 0;
 ContextMenuHighlight := 0;
End;

{ ============================================================================ }
{ === FIN DES PROCEDURES DU MENU CONTEXTUEL === }
{ ============================================================================ }

{ ProcÃ©dure pour dessiner la barre de menu principale }
Procedure DrawMenuBar;
Var
 I: Integer;
 TextX: Integer;
Begin
 { Dessiner le fond de la barre de menu }
 SetFillStyle(SolidFill, MENU_BAR_COLOR);
 Bar(0, 0, ScreenWidth, MENU_HEIGHT);

 { Dessiner une ligne de sÃ©paration }
 SetColor(DarkGray);
 Line(0, MENU_HEIGHT, ScreenWidth, MENU_HEIGHT);

 { Dessiner chaque Ã©lÃ©ment du menu }
 For I := 1 to MENU_COUNT do Begin
  TextX := MenuPositions[I];

  { Si ce menu est sÃ©lectionnÃ©, dessiner le fond en surbrillance }
  If (I = CurrentMenu) and (MenuState <> msNone) Then Begin
   SetFillStyle(SolidFill, MENU_HIGHLIGHT_BG);
   Bar(TextX - 4, 1, TextX + Length(MenuNames[I]) * 8 + 4, MENU_HEIGHT - 1);
   SetColor(MENU_HIGHLIGHT_FG);
  End
  Else Begin
   SetColor(MENU_TEXT_COLOR);
  End;

  { Dessiner le texte du menu }
  OutTextXY(TextX, 4, MenuNames[I]);
 End;
End;

{ Renvoie le nombre d'elements (separateurs inclus) d'un menu deroulant. }
Function GetMenuItemCount(MenuIndex: Integer): Integer;
Begin
 Case MenuIndex of
  1: GetMenuItemCount := 11;
  2: GetMenuItemCount := 12;
  3: GetMenuItemCount := 9;
  4: GetMenuItemCount := 6;
  5: GetMenuItemCount := 7;
  6: GetMenuItemCount := 10;
  7: GetMenuItemCount := 4;
  8: GetMenuItemCount := 4;
  9: GetMenuItemCount := 3;
  Else GetMenuItemCount := 0;
 End;
End;

{ Indique si la ligne d'index ItemIdx du menu MenuIndex est un separateur. }
Function IsMenuSeparator(MenuIndex, ItemIdx: Integer): Boolean;
Begin
 Case MenuIndex of
  1: IsMenuSeparator := (ItemIdx = 6) or (ItemIdx = 8);
  2: IsMenuSeparator := (ItemIdx = 3) or (ItemIdx = 8) or (ItemIdx = 10);
  3: IsMenuSeparator := (ItemIdx = 4) or (ItemIdx = 8);
  5: IsMenuSeparator := ItemIdx = 4;
  6: IsMenuSeparator := (ItemIdx = 3) or (ItemIdx = 6) or (ItemIdx = 9);
  7: IsMenuSeparator := ItemIdx = 3;
  9: IsMenuSeparator := ItemIdx = 2;
  Else IsMenuSeparator := False;
 End;
End;

{ ProcÃ©dure pour dessiner un sous-menu dÃ©roulant }
Procedure DrawDropDownMenu(MenuIndex: Integer);
Const
 MaxItems = 12;
 ItemHeight = 16;
 MenuWidth = 260;
Var
 X, Y, I, ItemCount: Integer;
 Items: Array[1..MaxItems] of String[20];
 Shortcuts: Array[1..MaxItems] of String[12];
Begin
 { DÃ©finir les Ã©lÃ©ments selon le menu sÃ©lectionnÃ© }
 Case Language Of
  _English: Begin
   Case MenuIndex of
  1: Begin { File }
      ItemCount := 11;
      Items[1] := 'New';
      Items[2] := 'Open...';
      Items[3] := 'Close';
      Items[4] := 'Save';
      Items[5] := 'Save As...';
      Items[6] := '-';
      Items[7] := 'Export...';
      Items[8] := '-';
      Items[9] := 'Print...';
      Items[10] := 'Print Preview';
      Items[11] := 'Exit';
     End;
  2: Begin { Edit }
      ItemCount := 12;
      Items[1] := 'Undo';
      Items[2] := 'Redo';
      Items[3] := '-';
      Items[4] := 'Cut';
      Items[5] := 'Copy';
      Items[6] := 'Paste';
      Items[7] := 'Delete';
      Items[8] := '-';
      Items[9] := 'Select All';
      Items[10] := '-';
      Items[11] := 'Find...';
      Items[12] := 'Replace...';
     End;
  3: Begin { View }
      ItemCount := 9;
      Items[1] := 'Zoom In';
      Items[2] := 'Zoom Out';
      Items[3] := 'Fit Page';
      Items[4] := '-';
      Items[5] := 'Grid';
      Items[6] := 'Rulers';
      Items[7] := 'Guides';
      Items[8] := '-';
      Items[9] := 'Snap to Grid';
     End;
  4: Begin { Insert }
      ItemCount := 6;
      Items[1] := 'Shape';
      Items[2] := 'Text Box';
      Items[3] := 'Image...';
      Items[4] := 'Connector';
      Items[5] := 'Page';
      Items[6] := 'Layer';
     End;
  5: Begin { Format }
      ItemCount := 7;
      Items[1] := 'Fill...';
      Items[2] := 'Line...';
      Items[3] := 'Text...';
      Items[4] := '-';
      Items[5] := 'Alignment';
      Items[6] := 'Group';
      Items[7] := 'Ungroup';
     End;
  6: Begin { Shape }
      ItemCount := 10;
      Items[1] := 'Rotate';
      Items[2] := 'Flip';
      Items[3] := '-';
      Items[4] := 'Align';
      Items[5] := 'Distribute';
      Items[6] := '-';
      Items[7] := 'Size';
      Items[8] := 'Position';
      Items[9] := '-';
      Items[10] := 'Operations';
     End;
  7: Begin { Tools }
      ItemCount := 4;
      Items[1] := 'Snap to Grid';
      Items[2] := 'Snap to Guides';
      Items[3] := '-';
      Items[4] := 'Options...';
     End;
  8: Begin { Window }
      ItemCount := 4;
      Items[1] := 'New Window';
      Items[2] := 'Cascade';
      Items[3] := 'Tile';
      Items[4] := 'Close All';
     End;
  9: Begin { Help }
      ItemCount := 3;
      Items[1] := 'Help Topics';
      Items[2] := '-';
      Items[3] := 'About Visio';
     End;
  Else
   ItemCount := 0;
   End;
  End;
  Else Begin { Francais par defaut }
   Case MenuIndex of
    1: Begin { Fichier }
        ItemCount := 11;
        Items[1] := 'Nouveau';
        Items[2] := 'Ouvrir...';
        Items[3] := 'Fermer';
        Items[4] := 'Enregistrer';
        Items[5] := 'Enregistrer sous...';
        Items[6] := '-';
        Items[7] := 'Exporter...';
        Items[8] := '-';
        Items[9] := 'Imprimer...';
        Items[10] := 'Apercu impression';
        Items[11] := 'Quitter';
       End;
    2: Begin { Edition }
        ItemCount := 12;
        Items[1] := 'Annuler';
        Items[2] := 'Retablir';
        Items[3] := '-';
        Items[4] := 'Couper';
        Items[5] := 'Copier';
        Items[6] := 'Coller';
        Items[7] := 'Supprimer';
        Items[8] := '-';
        Items[9] := 'Tout selectionner';
        Items[10] := '-';
        Items[11] := 'Rechercher...';
        Items[12] := 'Remplacer...';
       End;
    3: Begin { Affichage }
        ItemCount := 9;
        Items[1] := 'Zoom avant';
        Items[2] := 'Zoom arriere';
        Items[3] := 'Page entiere';
        Items[4] := '-';
        Items[5] := 'Grille';
        Items[6] := 'Regles';
        Items[7] := 'Reperes';
        Items[8] := '-';
        Items[9] := 'Aligner sur grille';
       End;
    4: Begin { Insertion }
        ItemCount := 6;
        Items[1] := 'Forme';
        Items[2] := 'Zone de texte';
        Items[3] := 'Image...';
        Items[4] := 'Connecteur';
        Items[5] := 'Page';
        Items[6] := 'Calque';
       End;
    5: Begin { Format }
        ItemCount := 7;
        Items[1] := 'Remplissage...';
        Items[2] := 'Trait...';
        Items[3] := 'Texte...';
        Items[4] := '-';
        Items[5] := 'Alignement';
        Items[6] := 'Grouper';
        Items[7] := 'Degrouper';
       End;
    6: Begin { Forme }
        ItemCount := 10;
        Items[1] := 'Rotation';
        Items[2] := 'Retournement';
        Items[3] := '-';
        Items[4] := 'Aligner';
        Items[5] := 'Distribuer';
        Items[6] := '-';
        Items[7] := 'Taille';
        Items[8] := 'Position';
        Items[9] := '-';
        Items[10] := 'Operations';
       End;
    7: Begin { Outils }
        ItemCount := 4;
        Items[1] := 'Aligner sur grille';
        Items[2] := 'Aligner sur reperes';
        Items[3] := '-';
        Items[4] := 'Options...';
       End;
    8: Begin { Fenetre }
        ItemCount := 4;
        Items[1] := 'Nouvelle fenetre';
        Items[2] := 'Cascade';
        Items[3] := 'Mosaique';
        Items[4] := 'Fermer tout';
       End;
    9: Begin { Aide }
        ItemCount := 3;
        Items[1] := 'Rubriques d''aide';
        Items[2] := '-';
        Items[3] := 'A propos de Visio';
       End;
    Else
     ItemCount := 0;
   End;
  End;
 End;

 If ItemCount = 0 Then Exit;

 { Raccourcis clavier (independants de la langue) }
 For I := 1 to MaxItems do Shortcuts[I] := '';
 Case MenuIndex of
  1: Begin { Fichier / File }
      Shortcuts[1] := 'Ctrl+N';
      Shortcuts[2] := 'Ctrl+O';
      Shortcuts[3] := 'Ctrl+W';
      Shortcuts[4] := 'Ctrl+S';
      Shortcuts[5] := 'F12';
      Shortcuts[9] := 'Ctrl+P';
      Shortcuts[11] := 'Alt+F4';
     End;
  2: Begin { Edition / Edit }
      Shortcuts[1] := 'Ctrl+Z';
      Shortcuts[2] := 'Ctrl+Y';
      Shortcuts[4] := 'Ctrl+X';
      Shortcuts[5] := 'Ctrl+C';
      Shortcuts[6] := 'Ctrl+V';
      Shortcuts[7] := 'Del';
      Shortcuts[9] := 'Ctrl+A';
      Shortcuts[11] := 'Ctrl+F';
      Shortcuts[12] := 'Ctrl+H';
     End;
  3: Begin { Affichage / View }
      Shortcuts[1] := 'Ctrl++';
      Shortcuts[2] := 'Ctrl+-';
      Shortcuts[3] := 'Ctrl+0';
     End;
  5: Begin { Format }
      Shortcuts[6] := 'Ctrl+G';
      Shortcuts[7] := 'Ctrl+Shift+G';
     End;
  9: Begin { Aide / Help }
      Shortcuts[1] := 'F1';
     End;
 End;

 { Calculer la position du menu dÃ©roulant }
 X := MenuPositions[MenuIndex] - 4;
 Y := MENU_HEIGHT + 1;

 { Dessiner le fond du menu dÃ©roulant }
 SetFillStyle(SolidFill, MENU_BAR_COLOR);
 Bar(X, Y, X + MenuWidth, Y + ItemCount * ItemHeight + 4);

 { Dessiner la bande de surlignage si un item non-separateur est survole }
 If (HoveredMenuItem >= 1) and (HoveredMenuItem <= ItemCount) and
    (Items[HoveredMenuItem] <> '-') Then Begin
  SetFillStyle(SolidFill, MENU_HIGHLIGHT_BG);
  Bar(X + 1, Y + (HoveredMenuItem - 1) * ItemHeight + 2,
      X + MenuWidth - 1, Y + HoveredMenuItem * ItemHeight + 2);
 End;

 { Dessiner la bordure }
 SetColor(DarkGray);
 Rectangle(X, Y, X + MenuWidth, Y + ItemCount * ItemHeight + 4);

 { Dessiner les Ã©lÃ©ments du menu }
 SetColor(MENU_TEXT_COLOR);
 For I := 1 to ItemCount do Begin
  If Items[I] = '-' Then Begin
   { Dessiner un sÃ©parateur }
   SetColor(DarkGray);
   Line(X + 5, Y + I * ItemHeight - 6, X + MenuWidth - 5, Y + I * ItemHeight - 6);
   SetColor(MENU_TEXT_COLOR);
  End
  Else Begin
   If I = HoveredMenuItem Then SetColor(MENU_HIGHLIGHT_FG)
                          Else SetColor(MENU_TEXT_COLOR);
   OutTextXY(X + 10, Y + (I - 1) * ItemHeight + 4, Items[I]);
   If Shortcuts[I] <> '' Then
    OutTextXY(X + MenuWidth - 5 - Length(Shortcuts[I]) * 8,
              Y + (I - 1) * ItemHeight + 4, Shortcuts[I]);
  End;
 End;
End;

{ Fonction pour dÃ©terminer quel menu est sous la souris }
Function GetMenuAtPosition(MouseX, MouseY: Integer): Integer;
Var
 I: Integer;
Begin
 GetMenuAtPosition := 0;

 { VÃ©rifier si on est dans la barre de menu }
 If (MouseY >= 0) and (MouseY <= MENU_HEIGHT) Then Begin
  For I := 1 to MENU_COUNT do Begin
   If (MouseX >= MenuPositions[I] - 4) and
      (MouseX <= MenuPositions[I] + Length(MenuNames[I]) * 8 + 4) Then Begin
    GetMenuAtPosition := I;
    Exit;
   End;
  End;
 End;
End;

{ Fonction utilitaire : conversion de chaine en majuscules (ASCII) }
Function StrToUpper(Const S:String):String;
Var I:Integer; R:String;
Begin
 R:=S;
 For I:=1 To Length(R) Do
  If(R[I]>='a')And(R[I]<='z')Then R[I]:=Chr(Ord(R[I])-32);
 StrToUpper:=R;
End;

{ ============================================================================ }
{ === BOITE DE DIALOGUE D'OUVERTURE/ENREGISTREMENT DE FICHIER (style Visio) === }
{ === Inspire de DEVENV.PAS - navigation repertoires + filtres VSD/VSDX/SVG  === }
{ ============================================================================ }

Const
 VFD_WIDTH         = 540;        { Largeur du dialogue }
 VFD_HEIGHT        = 400;        { Hauteur du dialogue }
 VFD_TITLE_H       = 22;         { Hauteur barre de titre }
 VFD_PAD           = 10;         { Marge interne }
 VFD_BTN_W         = 90;         { Largeur bouton OK/Annuler }
 VFD_BTN_H         = 24;         { Hauteur bouton }
 VFD_BTN_SP        = 12;         { Espacement entre boutons }
 VFD_INPUT_H       = 20;         { Hauteur champ saisie }
 VFD_FILTER_H      = 20;         { Hauteur selecteur filtre }
 VFD_LABEL_H       = 16;         { Hauteur etiquette }
 VFD_ROW_H         = 16;         { Hauteur ligne dans la liste }
 VFD_PATH_H        = 18;         { Hauteur affichage chemin }
 VFD_DRIVE_H       = 20;         { Hauteur barre de lecteurs }
 VFD_DRIVE_W       = 26;         { Largeur d'un bouton lecteur }
 VFD_MAX_FILES     = 512;        { Capacite maxi de la liste }
 VFD_MAX_FILTERS   = 32;         { Nb maxi de filtres }
 VFD_MAX_DRIVES    = 26;         { A..Z }
 VFD_FILTER_VISIBLE = 8;         { Lignes visibles dans le drop-down filtre }
 VFD_FILTER_SB_W   = 14;         { Largeur scrollbar drop-down filtre }
 VFD_FILTER_ARROW_H = 14;        { Hauteur des boutons fleche scrollbar filtre }

 { Couleurs (palette EGA/VGA 0..15) }
 VFD_CLR_BG        = 7;          { Fond du dialogue : LightGray }
 VFD_CLR_TITLE_BG  = 1;          { Fond titre : Blue }
 VFD_CLR_TITLE_FG  = 15;         { Texte titre : White }
 VFD_CLR_BORDER    = 0;          { Bordure : Black }
 VFD_CLR_SHADOW    = 8;          { Ombre : DarkGray }
 VFD_CLR_LIST_BG   = 15;         { Fond liste : White }
 VFD_CLR_LIST_FG   = 0;          { Texte liste : Black }
 VFD_CLR_DIR_FG    = 1;          { Repertoire : Blue }
 VFD_CLR_SEL_BG    = 1;          { Selection : Blue }
 VFD_CLR_SEL_FG    = 15;         { Texte selection : White }
 VFD_CLR_INPUT_BG  = 15;         { Fond saisie : White }
 VFD_CLR_INPUT_FG  = 0;          { Texte saisie : Black }
 VFD_CLR_BTN_BG    = 7;          { Fond bouton : LightGray }
 VFD_CLR_BTN_FG    = 0;          { Texte bouton : Black }
 VFD_CLR_BTN_FOCUS = 9;          { Focus bouton : LightBlue }
 VFD_CLR_SCROLL_BG = 8;          { Scrollbar fond }
 VFD_CLR_SCROLL_FG = 7;          { Scrollbar curseur }
 VFD_CLR_LABEL_FG  = 0;          { Texte etiquettes }
 VFD_CLR_DRIVE_BG  = 7;
 VFD_CLR_DRIVE_FG  = 0;

Type
 TVFDEntry = Record
  Name : String[63];
  IsDir: Boolean;
  Size : LongInt;
 End;

 TVFDFilter = Record
  Desc   : String[63];
  Pattern: String[63];   { peut contenir plusieurs masques separes par ';' }
 End;

Var
 { Etat global du dialogue (une seule instance modale a la fois) }
 VFD_Title       : String[63];
 VFD_X, VFD_Y    : Integer;
 VFD_W, VFD_H    : Integer;
 VFD_SaveMode    : Boolean;
 VFD_ExportMode  : Boolean;
 VFD_CurrentPath : String[255];
 VFD_SelectedFile: String[255];
 VFD_Files       : Array[0..VFD_MAX_FILES-1] Of TVFDEntry;
 VFD_FileCount   : Integer;
 VFD_Filters     : Array[0..VFD_MAX_FILTERS-1] Of TVFDFilter;
 VFD_FilterCount : Integer;
 VFD_FilterIndex : Integer;
 VFD_FilterScrollTop : Integer;  { Premier item visible dans le drop-down filtre }
 VFD_ScrollTop   : Integer;
 VFD_SelIndex    : Integer;
 VFD_InputText   : String[127];
 VFD_InputCursor : Integer;
 VFD_Result      : Integer;      { 0=ouvert, 1=OK, 2=Cancel }
 VFD_FilterOpen  : Boolean;      { Liste deroulante filtre ouverte }
 VFD_Drives      : Array[1..VFD_MAX_DRIVES] Of Char;
 VFD_DriveCount  : Integer;
 VFD_ListVisible : Integer;      { Nb de lignes visibles dans la liste }

{ Convertit en minuscules ASCII }
Function VFDLower(Const S: String): String;
Var I: Integer; R: String;
Begin
 R := S;
 For I := 1 To Length(R) Do
  If (R[I] >= 'A') And (R[I] <= 'Z') Then R[I] := Chr(Ord(R[I]) + 32);
 VFDLower := R;
End;

{ Recupere l'extension d'un nom de fichier (avec le point, en minuscules) }
Function VFDExt(Const S: String): String;
Var I, P: Integer;
Begin
 P := 0;
 For I := Length(S) DownTo 1 Do
  If S[I] = '.' Then Begin P := I; Break; End;
 If P = 0 Then VFDExt := ''
 Else VFDExt := VFDLower(Copy(S, P, Length(S) - P + 1));
End;

{ Teste si un nom correspond a un masque (un seul) du genre *.ext ou *.* }
Function VFDMatchOne(Const Name, Mask: String): Boolean;
Var ME, NE: String;
Begin
 If (Mask = '*.*') Or (Mask = '*') Or (Mask = '') Then Begin
  VFDMatchOne := True; Exit;
 End;
 ME := VFDExt(Mask);
 NE := VFDExt(Name);
 If ME = '' Then Begin VFDMatchOne := True; Exit; End;
 VFDMatchOne := (NE = ME);
End;

{ Teste si un nom correspond a un masque compose (separe par ';') }
Function VFDMatchPattern(Const Name, Pattern: String): Boolean;
Var P, Q: Integer; Tok: String;
Begin
 VFDMatchPattern := False;
 P := 1;
 While P <= Length(Pattern) Do Begin
  Q := P;
  While (Q <= Length(Pattern)) And (Pattern[Q] <> ';') Do Inc(Q);
  Tok := Copy(Pattern, P, Q - P);
  { Trim espaces }
  While (Length(Tok) > 0) And (Tok[1] = ' ') Do Delete(Tok, 1, 1);
  While (Length(Tok) > 0) And (Tok[Length(Tok)] = ' ') Do
   Delete(Tok, Length(Tok), 1);
  If VFDMatchOne(Name, Tok) Then Begin
   VFDMatchPattern := True; Exit;
  End;
  P := Q + 1;
 End;
End;

{ Normalise un chemin en s'assurant qu'il finit par '\' }
Procedure VFDEnsureTrailingSlash(Var P: String);
Begin
 If Length(P) = 0 Then Begin P := '\'; Exit; End;
 If (P[Length(P)] <> '\') And (P[Length(P)] <> '/') Then P := P + '\';
End;

{ Detecte les lecteurs disponibles (A..Z) via Dos.DiskSize }
Procedure VFDScanDrives;
Var I: Integer; Sz: LongInt;
Begin
 VFD_DriveCount := 0;
 For I := 1 To 26 Do Begin
  Sz := DiskSize(I);
  If Sz > 0 Then Begin
   Inc(VFD_DriveCount);
   VFD_Drives[VFD_DriveCount] := Chr(Ord('A') + I - 1);
  End;
 End;
End;

{ Tri (insertion) : repertoires d'abord, puis fichiers ; alpha ASCII insensitive }
Procedure VFDSortFiles;
Var I, J: Integer; Tmp: TVFDEntry;
 Function Less(Const A, B: TVFDEntry): Boolean;
 Begin
  If A.IsDir And Not B.IsDir Then Begin Less := True; Exit; End;
  If B.IsDir And Not A.IsDir Then Begin Less := False; Exit; End;
  Less := VFDLower(A.Name) < VFDLower(B.Name);
 End;
Begin
 For I := 1 To VFD_FileCount - 1 Do Begin
  Tmp := VFD_Files[I];
  J := I;
  While (J > 0) And Less(Tmp, VFD_Files[J - 1]) Do Begin
   VFD_Files[J] := VFD_Files[J - 1];
   Dec(J);
  End;
  VFD_Files[J] := Tmp;
 End;
End;

{ Charge le contenu du repertoire courant (filtre par le masque actif) }
Procedure VFDLoadDirectory;
Var SR: SearchRec; Pat: String;
Begin
 VFD_FileCount := 0;
 VFD_SelIndex := -1;
 VFD_ScrollTop := 0;
 { Entree parent '..' si on n'est pas a la racine }
 If (Length(VFD_CurrentPath) > 3) And (VFD_FileCount < VFD_MAX_FILES) Then
 Begin
  VFD_Files[VFD_FileCount].Name := '..';
  VFD_Files[VFD_FileCount].IsDir := True;
  VFD_Files[VFD_FileCount].Size := 0;
  Inc(VFD_FileCount);
 End;
 { Repertoires }
 FindFirst(VFD_CurrentPath + '*.*', Directory, SR);
 While (DosError = 0) And (VFD_FileCount < VFD_MAX_FILES) Do Begin
  If ((SR.Attr And Directory) <> 0) And (SR.Name <> '.') And
     (SR.Name <> '..') Then Begin
   VFD_Files[VFD_FileCount].Name := SR.Name;
   VFD_Files[VFD_FileCount].IsDir := True;
   VFD_Files[VFD_FileCount].Size := 0;
   Inc(VFD_FileCount);
  End;
  FindNext(SR);
 End;
 FindClose(SR);
 { Fichiers correspondant au filtre actif }
 If (VFD_FilterIndex >= 0) And (VFD_FilterIndex < VFD_FilterCount) Then
  Pat := VFD_Filters[VFD_FilterIndex].Pattern
 Else
  Pat := '*.*';
 FindFirst(VFD_CurrentPath + '*.*', AnyFile, SR);
 While (DosError = 0) And (VFD_FileCount < VFD_MAX_FILES) Do Begin
  If (SR.Attr And Directory) = 0 Then
   If VFDMatchPattern(SR.Name, Pat) Then Begin
    VFD_Files[VFD_FileCount].Name := SR.Name;
    VFD_Files[VFD_FileCount].IsDir := False;
    VFD_Files[VFD_FileCount].Size := SR.Size;
    Inc(VFD_FileCount);
   End;
  FindNext(SR);
 End;
 FindClose(SR);
 VFDSortFiles;
End;

{ Initialise les filtres standards Visio (selon la langue) }
Procedure VFDInitFilters;
 Procedure Add(Const D, P: String);
 Begin
  If VFD_FilterCount < VFD_MAX_FILTERS Then Begin
   VFD_Filters[VFD_FilterCount].Desc := D;
   VFD_Filters[VFD_FilterCount].Pattern := P;
   Inc(VFD_FilterCount);
  End;
 End;
Begin
 VFD_FilterCount := 0;
 If VFD_ExportMode Then Begin
  If Language = _English Then Begin
   Add('PNG image (*.PNG)',                    '*.PNG');
   Add('GIF image (*.GIF)',                    '*.GIF');
   Add('JPEG image (*.JPG;*.JPEG)',            '*.JPG;*.JPEG');
   Add('Windows bitmap (*.BMP;*.DIB)',         '*.BMP;*.DIB');
   Add('SVG vector (*.SVG)',                   '*.SVG');
   Add('ZSoft Paintbrush (*.PCX)',             '*.PCX');
   Add('Portable pixmap (*.PPM)',              '*.PPM');
   Add('TIFF image (*.TIF;*.TIFF)',            '*.TIF;*.TIFF');
   Add('WordPerfect Graphics (*.WPG)',         '*.WPG');
   Add('X11 bitmap (*.XBM)',                   '*.XBM');
   Add('Bitmap Genesis graphiX (*.BGX)',       '*.BGX');
   Add('CCITT G3 fax (*.FAX)',                 '*.FAX');
   Add('DICOM image (*.DCM)',                  '*.DCM');
   Add('IFF/ILBM Amiga (*.LBM)',               '*.LBM');
   Add('Canon RAW 2 (*.CR2)',                  '*.CR2');
   Add('Dr. HALO (*.CUT)',                     '*.CUT');
   Add('GEM/IMG image (*.GEM)',                '*.GEM');
   Add('Radiance RGBE (*.HDR)',                '*.HDR');
   Add('MacPaint (*.MAC)',                     '*.MAC');
   Add('Microsoft Paint (*.MSP)',              '*.MSP');
   Add('All files (*.*)',                      '*.*');
  End Else Begin
   Add('Image PNG (*.PNG)',                    '*.PNG');
   Add('Image GIF (*.GIF)',                    '*.GIF');
   Add('Image JPEG (*.JPG;*.JPEG)',            '*.JPG;*.JPEG');
   Add('Bitmap Windows (*.BMP;*.DIB)',         '*.BMP;*.DIB');
   Add('Vectoriel SVG (*.SVG)',                '*.SVG');
   Add('ZSoft Paintbrush (*.PCX)',             '*.PCX');
   Add('Pixmap portable (*.PPM)',              '*.PPM');
   Add('Image TIFF (*.TIF;*.TIFF)',            '*.TIF;*.TIFF');
   Add('WordPerfect Graphics (*.WPG)',         '*.WPG');
   Add('Bitmap X11 (*.XBM)',                   '*.XBM');
   Add('Bitmap Genesis graphiX (*.BGX)',       '*.BGX');
   Add('Fax CCITT G3 (*.FAX)',                 '*.FAX');
   Add('Image DICOM (*.DCM)',                  '*.DCM');
   Add('IFF/ILBM Amiga (*.LBM)',               '*.LBM');
   Add('Canon RAW 2 (*.CR2)',                  '*.CR2');
   Add('Dr. HALO (*.CUT)',                     '*.CUT');
   Add('Image GEM/IMG (*.GEM)',                '*.GEM');
   Add('Radiance RGBE (*.HDR)',                '*.HDR');
   Add('MacPaint (*.MAC)',                     '*.MAC');
   Add('Microsoft Paint (*.MSP)',              '*.MSP');
   Add('Tous les fichiers (*.*)',              '*.*');
  End;
 End Else If Language = _English Then Begin
  Add('All Visio files (*.VSD;*.VSDX;*.SVG)', '*.VSD;*.VSDX;*.SVG');
  Add('Visio 2003 binary (*.VSD)',           '*.VSD');
  Add('Visio 2013+ XML (*.VSDX)',            '*.VSDX');
  Add('SVG vector (*.SVG)',                  '*.SVG');
  Add('All files (*.*)',                     '*.*');
 End Else Begin
  Add('Tous les fichiers Visio (*.VSD;*.VSDX;*.SVG)', '*.VSD;*.VSDX;*.SVG');
  Add('Visio 2003 binaire (*.VSD)',          '*.VSD');
  Add('Visio 2013+ XML (*.VSDX)',            '*.VSDX');
  Add('Vectoriel SVG (*.SVG)',               '*.SVG');
  Add('Tous les fichiers (*.*)',             '*.*');
 End;
 VFD_FilterIndex := 0;
End;

{ Initialise le dialogue (etat global) }
Procedure VFDInit(Const Title: String; SaveMode: Boolean;
                  Const DefaultName: String);
Begin
 VFD_Title := Title;
 VFD_W := VFD_WIDTH; VFD_H := VFD_HEIGHT;
 VFD_X := (ScreenWidth - VFD_W) Div 2;
 VFD_Y := (ScreenHeight - VFD_H) Div 2;
 If VFD_X < 0 Then VFD_X := 0;
 If VFD_Y < 0 Then VFD_Y := 0;
 VFD_SaveMode := SaveMode;
 GetDir(0, VFD_CurrentPath);
 VFDEnsureTrailingSlash(VFD_CurrentPath);
 VFD_SelectedFile := '';
 VFD_InputText := DefaultName;
 VFD_InputCursor := Length(DefaultName);
 VFD_Result := 0;
 VFD_FilterOpen := False;
 VFD_FilterScrollTop := 0;
 VFDInitFilters;
 VFDScanDrives;
 VFDLoadDirectory;
End;

{ Dessine un bouton 3D (style Windows 3.1) }
Procedure VFDDrawButton(X, Y, W, H: Integer; Const Caption: String;
                        Focused: Boolean);
Var BG, FG: Integer; TX, TY: Integer;
Begin
 If Focused Then Begin BG := VFD_CLR_BTN_FOCUS; FG := 15; End
            Else Begin BG := VFD_CLR_BTN_BG;    FG := VFD_CLR_BTN_FG; End;
 SetFillStyle(SolidFill, BG);
 Bar(X, Y, X + W - 1, Y + H - 1);
 { Relief 3D }
 SetColor(15);
 Line(X, Y, X + W - 1, Y);
 Line(X, Y, X, Y + H - 1);
 SetColor(VFD_CLR_SHADOW);
 Line(X + W - 1, Y, X + W - 1, Y + H - 1);
 Line(X, Y + H - 1, X + W - 1, Y + H - 1);
 SetColor(VFD_CLR_BORDER);
 Rectangle(X - 1, Y - 1, X + W, Y + H);
 SetColor(FG);
 TX := X + (W - TextWidth(Caption)) Div 2;
 TY := Y + (H - TextHeight(Caption)) Div 2;
 OutTextXY(TX, TY, Caption);
End;

{ Dessine le cadre principal + barre titre }
Procedure VFDDrawFrame;
Var X1, Y1, X2, Y2: Integer;
Begin
 X1 := VFD_X; Y1 := VFD_Y;
 X2 := X1 + VFD_W - 1; Y2 := Y1 + VFD_H - 1;
 { Ombre portee }
 SetFillStyle(SolidFill, VFD_CLR_SHADOW);
 Bar(X1 + 6, Y2 + 1, X2 + 6, Y2 + 6);
 Bar(X2 + 1, Y1 + 6, X2 + 6, Y2 + 6);
 { Fond }
 SetFillStyle(SolidFill, VFD_CLR_BG);
 Bar(X1, Y1, X2, Y2);
 { Bordure exterieure }
 SetColor(VFD_CLR_BORDER);
 Rectangle(X1, Y1, X2, Y2);
 { Barre de titre }
 SetFillStyle(SolidFill, VFD_CLR_TITLE_BG);
 Bar(X1 + 2, Y1 + 2, X2 - 2, Y1 + VFD_TITLE_H - 1);
 SetColor(VFD_CLR_TITLE_FG);
 OutTextXY(X1 + VFD_PAD, Y1 + 5, VFD_Title);
 { Bouton X de fermeture }
 SetFillStyle(SolidFill, VFD_CLR_BTN_BG);
 Bar(X2 - 22, Y1 + 4, X2 - 6, Y1 + VFD_TITLE_H - 3);
 SetColor(VFD_CLR_BORDER);
 Rectangle(X2 - 22, Y1 + 4, X2 - 6, Y1 + VFD_TITLE_H - 3);
 OutTextXY(X2 - 18, Y1 + 6, 'X');
End;

{ Calcule le rectangle de la liste de fichiers }
Procedure VFDListRect(Var X1, Y1, X2, Y2: Integer);
Begin
 X1 := VFD_X + VFD_PAD;
 Y1 := VFD_Y + VFD_TITLE_H + VFD_PAD + VFD_DRIVE_H + 4
       + VFD_PATH_H + 4 + VFD_LABEL_H;
 X2 := VFD_X + VFD_W - VFD_PAD;
 Y2 := VFD_Y + VFD_H - VFD_PAD - VFD_BTN_H - VFD_PAD
       - VFD_FILTER_H - VFD_LABEL_H - VFD_PAD
       - VFD_INPUT_H - VFD_LABEL_H - 4;
End;

{ Dessine la barre des lecteurs (A:, B:, C:, ...) }
Procedure VFDDrawDrives;
Var I, BX, BY: Integer; Cap: String;
Begin
 BY := VFD_Y + VFD_TITLE_H + VFD_PAD;
 SetColor(VFD_CLR_LABEL_FG);
 If Language = _English Then OutTextXY(VFD_X + VFD_PAD, BY, 'Drives:')
                        Else OutTextXY(VFD_X + VFD_PAD, BY, 'Lecteurs :');
 BY := BY + VFD_LABEL_H - 2;
 For I := 1 To VFD_DriveCount Do Begin
  BX := VFD_X + VFD_PAD + (I - 1) * (VFD_DRIVE_W + 2);
  If BX + VFD_DRIVE_W > VFD_X + VFD_W - VFD_PAD Then Break;
  Cap := VFD_Drives[I] + ':';
  If (Length(VFD_CurrentPath) >= 2) And
     (StrToUpper(VFD_CurrentPath)[1] = VFD_Drives[I]) And
     (VFD_CurrentPath[2] = ':') Then
   VFDDrawButton(BX, BY, VFD_DRIVE_W, VFD_DRIVE_H, Cap, True)
  Else
   VFDDrawButton(BX, BY, VFD_DRIVE_W, VFD_DRIVE_H, Cap, False);
 End;
End;

{ Dessine le chemin courant }
Procedure VFDDrawPath;
Var PY: Integer; S: String;
Begin
 PY := VFD_Y + VFD_TITLE_H + VFD_PAD + VFD_LABEL_H - 2
       + VFD_DRIVE_H + 4;
 SetColor(VFD_CLR_LABEL_FG);
 If Language = _English Then S := 'Path: ' Else S := 'Chemin : ';
 OutTextXY(VFD_X + VFD_PAD, PY, S + VFD_CurrentPath);
End;

{ Dessine la liste de fichiers }
Procedure VFDDrawList;
Var X1, Y1, X2, Y2, I, Row, TY, LH: Integer;
    Disp: String;
Begin
 VFDListRect(X1, Y1, X2, Y2);
 LH := Y2 - Y1 + 1;
 VFD_ListVisible := LH Div VFD_ROW_H;
 { Etiquette }
 SetColor(VFD_CLR_LABEL_FG);
 If Language = _English Then
  OutTextXY(X1, Y1 - VFD_LABEL_H, 'Files and folders:')
 Else
  OutTextXY(X1, Y1 - VFD_LABEL_H, 'Fichiers et dossiers :');
 { Cadre liste }
 SetFillStyle(SolidFill, VFD_CLR_LIST_BG);
 Bar(X1, Y1, X2, Y2);
 SetColor(VFD_CLR_BORDER);
 Rectangle(X1, Y1, X2, Y2);
 { Lignes }
 Row := 0;
 I := VFD_ScrollTop;
 While (I < VFD_FileCount) And (Row < VFD_ListVisible) Do Begin
  TY := Y1 + 2 + Row * VFD_ROW_H;
  If I = VFD_SelIndex Then Begin
   SetFillStyle(SolidFill, VFD_CLR_SEL_BG);
   Bar(X1 + 2, TY, X2 - 14, TY + VFD_ROW_H - 1);
   SetColor(VFD_CLR_SEL_FG);
  End Else Begin
   If VFD_Files[I].IsDir Then SetColor(VFD_CLR_DIR_FG)
                         Else SetColor(VFD_CLR_LIST_FG);
  End;
  If VFD_Files[I].IsDir Then
   Disp := '[' + VFD_Files[I].Name + ']'
  Else
   Disp := VFD_Files[I].Name;
  OutTextXY(X1 + 6, TY + 2, Disp);
  Inc(Row); Inc(I);
 End;
 { Scrollbar (esthetique) }
 SetFillStyle(SolidFill, VFD_CLR_SCROLL_BG);
 Bar(X2 - 12, Y1 + 1, X2 - 1, Y2 - 1);
 If VFD_FileCount > VFD_ListVisible Then Begin
  SetFillStyle(SolidFill, VFD_CLR_SCROLL_FG);
  Bar(X2 - 11, Y1 + 2 + (VFD_ScrollTop * (LH - 24)) Div
                       (VFD_FileCount + 1),
      X2 - 2, Y1 + 2 + (VFD_ScrollTop * (LH - 24)) Div
                       (VFD_FileCount + 1) + 18);
 End;
End;

{ Dessine le champ saisie nom de fichier }
Procedure VFDDrawInput;
Var IX, IY, IW: Integer; CX: Integer;
Begin
 IX := VFD_X + VFD_PAD;
 IW := VFD_W - 2 * VFD_PAD;
 IY := VFD_Y + VFD_H - VFD_PAD - VFD_BTN_H - VFD_PAD
       - VFD_FILTER_H - VFD_LABEL_H - VFD_PAD - VFD_INPUT_H;
 SetColor(VFD_CLR_LABEL_FG);
 If Language = _English Then
  OutTextXY(IX, IY - VFD_LABEL_H, 'File name:')
 Else
  OutTextXY(IX, IY - VFD_LABEL_H, 'Nom du fichier :');
 SetFillStyle(SolidFill, VFD_CLR_INPUT_BG);
 Bar(IX, IY, IX + IW - 1, IY + VFD_INPUT_H - 1);
 SetColor(VFD_CLR_BORDER);
 Rectangle(IX, IY, IX + IW - 1, IY + VFD_INPUT_H - 1);
 SetColor(VFD_CLR_INPUT_FG);
 OutTextXY(IX + 4, IY + 3, VFD_InputText);
 { Curseur }
 CX := IX + 4 + TextWidth(Copy(VFD_InputText, 1, VFD_InputCursor));
 SetColor(VFD_CLR_BORDER);
 Line(CX, IY + 3, CX, IY + VFD_INPUT_H - 4);
End;

{ Dessine une fleche triangulaire pointant vers le haut (centree en CX, TopY) }
Procedure VFDArrowUp(CX, TopY, Size: Integer);
Var I: Integer;
Begin
 For I := 0 To Size - 1 Do
  Line(CX - I, TopY + I, CX + I, TopY + I);
End;

{ Dessine une fleche triangulaire pointant vers le bas }
Procedure VFDArrowDown(CX, TopY, Size: Integer);
Var I: Integer;
Begin
 For I := 0 To Size - 1 Do
  Line(CX - (Size - 1 - I), TopY + I, CX + (Size - 1 - I), TopY + I);
End;

{ Rectangle du combo-box filtre (la zone fermee, sans drop-down) }
Procedure VFDFilterComboRect(Var FX, FY, FW: Integer);
Begin
 FX := VFD_X + VFD_PAD;
 FW := VFD_W - 2 * VFD_PAD;
 FY := VFD_Y + VFD_H - VFD_PAD - VFD_BTN_H - VFD_PAD - VFD_FILTER_H;
End;

{ Nombre de lignes effectivement visibles dans le drop-down filtre }
Function VFDFilterListVisible: Integer;
Begin
 If VFD_FilterCount < VFD_FILTER_VISIBLE Then
  VFDFilterListVisible := VFD_FilterCount
 Else
  VFDFilterListVisible := VFD_FILTER_VISIBLE;
End;

{ Rectangle de la liste deroulante (au-dessus du combo) }
Procedure VFDFilterListRect(Var LX, LY, LW, LH: Integer);
Var FX, FY, FW, NVis: Integer;
Begin
 VFDFilterComboRect(FX, FY, FW);
 NVis := VFDFilterListVisible;
 If NVis < 1 Then NVis := 1;
 LX := FX;
 LW := FW;
 LH := NVis * VFD_ROW_H + 2;
 LY := FY - LH - 1;
End;

{ Rectangle du bouton fleche-haut de la scrollbar du drop-down }
Procedure VFDFilterScrollUpRect(Var SX, SY, SW, SH: Integer);
Var LX, LY, LW, LH: Integer;
Begin
 VFDFilterListRect(LX, LY, LW, LH);
 SW := VFD_FILTER_SB_W;
 SH := VFD_FILTER_ARROW_H;
 SX := LX + LW - SW - 1;
 SY := LY + 1;
End;

{ Rectangle du bouton fleche-bas de la scrollbar du drop-down }
Procedure VFDFilterScrollDownRect(Var SX, SY, SW, SH: Integer);
Var LX, LY, LW, LH: Integer;
Begin
 VFDFilterListRect(LX, LY, LW, LH);
 SW := VFD_FILTER_SB_W;
 SH := VFD_FILTER_ARROW_H;
 SX := LX + LW - SW - 1;
 SY := LY + LH - SH - 1;
End;

{ Ajuste VFD_FilterScrollTop pour garder VFD_FilterIndex visible }
Procedure VFDFilterEnsureVisible;
Var NVis: Integer;
Begin
 NVis := VFDFilterListVisible;
 If NVis < 1 Then Begin VFD_FilterScrollTop := 0; Exit; End;
 If VFD_FilterIndex < VFD_FilterScrollTop Then
  VFD_FilterScrollTop := VFD_FilterIndex
 Else If VFD_FilterIndex >= VFD_FilterScrollTop + NVis Then
  VFD_FilterScrollTop := VFD_FilterIndex - NVis + 1;
 If VFD_FilterScrollTop < 0 Then VFD_FilterScrollTop := 0;
 If VFD_FilterScrollTop > VFD_FilterCount - NVis Then
  VFD_FilterScrollTop := VFD_FilterCount - NVis;
 If VFD_FilterScrollTop < 0 Then VFD_FilterScrollTop := 0;
End;

{ Dessine le selecteur de filtre (ferme : combo-box) }
Procedure VFDDrawFilter;
Var FX, FY, FW: Integer; Txt: String;
    ArrowCX, ArrowTop: Integer;
Begin
 VFDFilterComboRect(FX, FY, FW);
 SetColor(VFD_CLR_LABEL_FG);
 If Language = _English Then
  OutTextXY(FX, FY - VFD_LABEL_H, 'File type:')
 Else
  OutTextXY(FX, FY - VFD_LABEL_H, 'Type de fichier :');
 SetFillStyle(SolidFill, VFD_CLR_INPUT_BG);
 Bar(FX, FY, FX + FW - 1, FY + VFD_FILTER_H - 1);
 SetColor(VFD_CLR_BORDER);
 Rectangle(FX, FY, FX + FW - 1, FY + VFD_FILTER_H - 1);
 If (VFD_FilterIndex >= 0) And (VFD_FilterIndex < VFD_FilterCount) Then
  Txt := VFD_Filters[VFD_FilterIndex].Desc
 Else
  Txt := '*.*';
 SetColor(VFD_CLR_INPUT_FG);
 OutTextXY(FX + 4, FY + 3, Txt);
 { Bouton fleche descendante a droite }
 SetFillStyle(SolidFill, VFD_CLR_BTN_BG);
 Bar(FX + FW - 18, FY + 1, FX + FW - 2, FY + VFD_FILTER_H - 2);
 SetColor(VFD_CLR_BORDER);
 Rectangle(FX + FW - 18, FY + 1, FX + FW - 2, FY + VFD_FILTER_H - 2);
 SetColor(VFD_CLR_BTN_FG);
 ArrowCX  := FX + FW - 10;
 ArrowTop := FY + (VFD_FILTER_H Div 2) - 2;
 VFDArrowDown(ArrowCX, ArrowTop, 5);
End;

{ Dessine la liste deroulante du filtre quand elle est ouverte. A appeler }
{ EN DERNIER dans VFDDraw pour qu'elle soit au-dessus de tout le reste.   }
Procedure VFDDrawFilterDropdown;
Var LX, LY, LW, LH, InnerW: Integer;
    NVis, Row, I, TY: Integer;
    SUX, SUY, SUW, SUH: Integer;
    SDX, SDY, SDW, SDH: Integer;
    TrackTop, TrackBot, TrackH, ThumbH, ThumbY: Integer;
Begin
 If Not VFD_FilterOpen Then Exit;
 NVis := VFDFilterListVisible;
 If NVis <= 0 Then Exit;
 VFDFilterListRect(LX, LY, LW, LH);
 InnerW := LW - VFD_FILTER_SB_W - 2;
 { Cadre + fond }
 SetFillStyle(SolidFill, VFD_CLR_INPUT_BG);
 Bar(LX, LY, LX + LW - 1, LY + LH - 1);
 SetColor(VFD_CLR_BORDER);
 Rectangle(LX, LY, LX + LW - 1, LY + LH - 1);
 { Lignes }
 For Row := 0 To NVis - 1 Do Begin
  I := VFD_FilterScrollTop + Row;
  If I >= VFD_FilterCount Then Break;
  TY := LY + 1 + Row * VFD_ROW_H;
  If I = VFD_FilterIndex Then Begin
   SetFillStyle(SolidFill, VFD_CLR_SEL_BG);
   Bar(LX + 1, TY, LX + InnerW, TY + VFD_ROW_H - 1);
   SetColor(VFD_CLR_SEL_FG);
  End Else
   SetColor(VFD_CLR_INPUT_FG);
  OutTextXY(LX + 4, TY + 2, VFD_Filters[I].Desc);
 End;
 { Scrollbar : fond piste }
 SetFillStyle(SolidFill, VFD_CLR_SCROLL_BG);
 Bar(LX + LW - VFD_FILTER_SB_W - 1, LY + 1,
     LX + LW - 2,                   LY + LH - 2);
 { Boutons fleches }
 VFDFilterScrollUpRect(SUX, SUY, SUW, SUH);
 VFDFilterScrollDownRect(SDX, SDY, SDW, SDH);
 SetFillStyle(SolidFill, VFD_CLR_BTN_BG);
 Bar(SUX, SUY, SUX + SUW - 1, SUY + SUH - 1);
 SetColor(VFD_CLR_BORDER);
 Rectangle(SUX, SUY, SUX + SUW - 1, SUY + SUH - 1);
 SetColor(VFD_CLR_BTN_FG);
 VFDArrowUp(SUX + SUW Div 2, SUY + 3, 5);
 SetFillStyle(SolidFill, VFD_CLR_BTN_BG);
 Bar(SDX, SDY, SDX + SDW - 1, SDY + SDH - 1);
 SetColor(VFD_CLR_BORDER);
 Rectangle(SDX, SDY, SDX + SDW - 1, SDY + SDH - 1);
 SetColor(VFD_CLR_BTN_FG);
 VFDArrowDown(SDX + SDW Div 2, SDY + 3, 5);
 { Thumb }
 If (VFD_FilterCount > NVis) Then Begin
  TrackTop := SUY + SUH + 1;
  TrackBot := SDY - 2;
  TrackH   := TrackBot - TrackTop + 1;
  If TrackH > 0 Then Begin
   ThumbH := (TrackH * NVis) Div VFD_FilterCount;
   If ThumbH < 8 Then ThumbH := 8;
   If ThumbH > TrackH Then ThumbH := TrackH;
   ThumbY := TrackTop +
             (VFD_FilterScrollTop * (TrackH - ThumbH))
              Div (VFD_FilterCount - NVis);
   SetFillStyle(SolidFill, VFD_CLR_SCROLL_FG);
   Bar(SUX + 1, ThumbY, SUX + SUW - 2, ThumbY + ThumbH - 1);
   SetColor(VFD_CLR_BORDER);
   Rectangle(SUX + 1, ThumbY, SUX + SUW - 2, ThumbY + ThumbH - 1);
  End;
 End;
End;

{ Dessine les boutons OK / Annuler }
Procedure VFDDrawButtons;
Var BX, BY: Integer; OKLab, CnLab: String;
Begin
 BY := VFD_Y + VFD_H - VFD_PAD - VFD_BTN_H;
 BX := VFD_X + VFD_W - VFD_PAD - VFD_BTN_W;
 If VFD_SaveMode Then Begin
  If Language = _English Then OKLab := 'Save' Else OKLab := 'Enregistrer';
 End Else Begin
  If Language = _English Then OKLab := 'Open' Else OKLab := 'Ouvrir';
 End;
 If Language = _English Then CnLab := 'Cancel' Else CnLab := 'Annuler';
 VFDDrawButton(BX, BY, VFD_BTN_W, VFD_BTN_H, OKLab, True);
 VFDDrawButton(BX - VFD_BTN_SP - VFD_BTN_W, BY,
               VFD_BTN_W, VFD_BTN_H, CnLab, False);
End;

{ Dessine le dialogue complet }
Procedure VFDDraw;
Begin
 VFDDrawFrame;
 VFDDrawDrives;
 VFDDrawPath;
 VFDDrawList;
 VFDDrawInput;
 VFDDrawFilter;
 VFDDrawButtons;
 VFDDrawFilterDropdown;   { dessine en dernier pour etre au-dessus }
End;

{ Test : (X,Y) est-il dans le rectangle [X1,Y1,X2,Y2] ? }
Function VFDInRect(X, Y, X1, Y1, X2, Y2: Integer): Boolean;
Begin
 VFDInRect := (X >= X1) And (X <= X2) And (Y >= Y1) And (Y <= Y2);
End;

{ Retourne l'index de la ligne cliquee dans la liste (-1 si aucun) }
Function VFDHitList(MX, MY: Integer): Integer;
Var X1, Y1, X2, Y2, Row: Integer;
Begin
 VFDHitList := -1;
 VFDListRect(X1, Y1, X2, Y2);
 If VFDInRect(MX, MY, X1, Y1, X2 - 14, Y2) Then Begin
  Row := (MY - Y1 - 2) Div VFD_ROW_H;
  If (Row >= 0) And (VFD_ScrollTop + Row < VFD_FileCount) Then
   VFDHitList := VFD_ScrollTop + Row;
 End;
End;

{ Retourne l'index du bouton clique : 0=OK, 1=Cancel, -1 sinon }
Function VFDHitButton(MX, MY: Integer): Integer;
Var BX, BY: Integer;
Begin
 VFDHitButton := -1;
 BY := VFD_Y + VFD_H - VFD_PAD - VFD_BTN_H;
 BX := VFD_X + VFD_W - VFD_PAD - VFD_BTN_W;
 If VFDInRect(MX, MY, BX, BY, BX + VFD_BTN_W - 1, BY + VFD_BTN_H - 1) Then
 Begin VFDHitButton := 0; Exit; End;
 BX := BX - VFD_BTN_SP - VFD_BTN_W;
 If VFDInRect(MX, MY, BX, BY, BX + VFD_BTN_W - 1, BY + VFD_BTN_H - 1) Then
  VFDHitButton := 1;
End;

{ Retourne l'index du lecteur clique (-1 si aucun) }
Function VFDHitDrive(MX, MY: Integer): Integer;
Var I, BX, BY: Integer;
Begin
 VFDHitDrive := -1;
 BY := VFD_Y + VFD_TITLE_H + VFD_PAD + VFD_LABEL_H - 2;
 For I := 1 To VFD_DriveCount Do Begin
  BX := VFD_X + VFD_PAD + (I - 1) * (VFD_DRIVE_W + 2);
  If BX + VFD_DRIVE_W > VFD_X + VFD_W - VFD_PAD Then Break;
  If VFDInRect(MX, MY, BX, BY,
               BX + VFD_DRIVE_W - 1, BY + VFD_DRIVE_H - 1) Then Begin
   VFDHitDrive := I; Exit;
  End;
 End;
End;

{ Teste si (MX,MY) est sur le selecteur de filtre }
Function VFDHitFilter(MX, MY: Integer): Boolean;
Var FX, FY, FW: Integer;
Begin
 FX := VFD_X + VFD_PAD;
 FW := VFD_W - 2 * VFD_PAD;
 FY := VFD_Y + VFD_H - VFD_PAD - VFD_BTN_H - VFD_PAD - VFD_FILTER_H;
 VFDHitFilter := VFDInRect(MX, MY, FX, FY,
                           FX + FW - 1, FY + VFD_FILTER_H - 1);
End;

{ Retourne l'index de la ligne cliquee dans le drop-down filtre (-1 si aucun) }
Function VFDHitFilterRow(MX, MY: Integer): Integer;
Var LX, LY, LW, LH, InnerW, Row: Integer;
Begin
 VFDHitFilterRow := -1;
 If Not VFD_FilterOpen Then Exit;
 VFDFilterListRect(LX, LY, LW, LH);
 InnerW := LW - VFD_FILTER_SB_W - 2;
 If VFDInRect(MX, MY, LX + 1, LY + 1,
              LX + InnerW, LY + LH - 2) Then Begin
  Row := (MY - (LY + 1)) Div VFD_ROW_H;
  If (Row >= 0) And (VFD_FilterScrollTop + Row < VFD_FilterCount) Then
   VFDHitFilterRow := VFD_FilterScrollTop + Row;
 End;
End;

{ Teste si (MX,MY) est sur la fleche-haut de la scrollbar du drop-down }
Function VFDHitFilterArrowUp(MX, MY: Integer): Boolean;
Var SX, SY, SW, SH: Integer;
Begin
 VFDHitFilterArrowUp := False;
 If Not VFD_FilterOpen Then Exit;
 VFDFilterScrollUpRect(SX, SY, SW, SH);
 VFDHitFilterArrowUp := VFDInRect(MX, MY, SX, SY,
                                  SX + SW - 1, SY + SH - 1);
End;

{ Teste si (MX,MY) est sur la fleche-bas de la scrollbar du drop-down }
Function VFDHitFilterArrowDown(MX, MY: Integer): Boolean;
Var SX, SY, SW, SH: Integer;
Begin
 VFDHitFilterArrowDown := False;
 If Not VFD_FilterOpen Then Exit;
 VFDFilterScrollDownRect(SX, SY, SW, SH);
 VFDHitFilterArrowDown := VFDInRect(MX, MY, SX, SY,
                                    SX + SW - 1, SY + SH - 1);
End;

{ Teste si (MX,MY) est sur la piste de la scrollbar (hors fleches) }
Function VFDHitFilterTrack(MX, MY: Integer): Boolean;
Var LX, LY, LW, LH, SUX, SUY, SUW, SUH: Integer;
    SDX, SDY, SDW, SDH: Integer;
Begin
 VFDHitFilterTrack := False;
 If Not VFD_FilterOpen Then Exit;
 VFDFilterListRect(LX, LY, LW, LH);
 VFDFilterScrollUpRect(SUX, SUY, SUW, SUH);
 VFDFilterScrollDownRect(SDX, SDY, SDW, SDH);
 VFDHitFilterTrack := VFDInRect(MX, MY,
  SUX, SUY + SUH,
  SUX + SUW - 1, SDY - 1);
End;

{ Teste si (MX,MY) est entierement dans la zone du drop-down ouvert }
Function VFDHitFilterDropdown(MX, MY: Integer): Boolean;
Var LX, LY, LW, LH: Integer;
Begin
 VFDHitFilterDropdown := False;
 If Not VFD_FilterOpen Then Exit;
 VFDFilterListRect(LX, LY, LW, LH);
 VFDHitFilterDropdown := VFDInRect(MX, MY, LX, LY,
                                   LX + LW - 1, LY + LH - 1);
End;

{ Teste si (MX,MY) est sur le bouton fermer X de la barre titre }
Function VFDHitClose(MX, MY: Integer): Boolean;
Begin
 VFDHitClose := VFDInRect(MX, MY,
  VFD_X + VFD_W - 23, VFD_Y + 4,
  VFD_X + VFD_W - 7,  VFD_Y + VFD_TITLE_H - 3);
End;

{ Navigation : monter d'un niveau }
Procedure VFDGoUp;
Var P: String; I: Integer;
Begin
 P := VFD_CurrentPath;
 { Retirer le slash final }
 If (Length(P) > 0) And
    ((P[Length(P)] = '\') Or (P[Length(P)] = '/')) Then
  Dec(P[0]);
 { Trouver le dernier slash }
 I := Length(P);
 While (I > 0) And (P[I] <> '\') And (P[I] <> '/') Do Dec(I);
 If I <= 3 Then Begin
  { Racine du lecteur }
  If (Length(P) >= 2) And (P[2] = ':') Then
   P := Copy(P, 1, 2) + '\'
  Else
   P := '\';
 End Else
  P := Copy(P, 1, I);
 VFD_CurrentPath := P;
 VFDEnsureTrailingSlash(VFD_CurrentPath);
 VFDLoadDirectory;
End;

{ Navigation : entrer dans un sous-repertoire }
Procedure VFDEnterDir(Const Name: String);
Begin
 If Name = '..' Then Begin VFDGoUp; Exit; End;
 VFD_CurrentPath := VFD_CurrentPath + Name;
 VFDEnsureTrailingSlash(VFD_CurrentPath);
 VFDLoadDirectory;
End;

{ Change de lecteur }
Procedure VFDChangeDrive(DriveIdx: Integer);
Var NewPath: String;
Begin
 If (DriveIdx < 1) Or (DriveIdx > VFD_DriveCount) Then Exit;
 NewPath := VFD_Drives[DriveIdx] + ':\';
 { Verifier que le lecteur est accessible }
 If DiskSize(Ord(VFD_Drives[DriveIdx]) - Ord('A') + 1) <= 0 Then Exit;
 VFD_CurrentPath := NewPath;
 VFDLoadDirectory;
End;

{ Cycle le filtre suivant }
Function VFDFilterPrimaryExt: String; Forward;

{ Selectionne un filtre donne et applique ses effets (extension auto + reload) }
Procedure VFDApplyFilter(NewIdx: Integer);
Var NewExt: String; DotPos, I: Integer;
Begin
 If VFD_FilterCount = 0 Then Exit;
 If NewIdx < 0 Then NewIdx := 0;
 If NewIdx >= VFD_FilterCount Then NewIdx := VFD_FilterCount - 1;
 VFD_FilterIndex := NewIdx;
 If VFD_ExportMode And (Length(VFD_InputText) > 0) Then Begin
  NewExt := VFDFilterPrimaryExt;
  If Length(NewExt) > 0 Then Begin
   DotPos := 0;
   For I := Length(VFD_InputText) DownTo 1 Do Begin
    If (VFD_InputText[I] = '\') Or (VFD_InputText[I] = '/') Then Break;
    If VFD_InputText[I] = '.' Then Begin DotPos := I; Break; End;
   End;
   If DotPos > 0 Then
    VFD_InputText := Copy(VFD_InputText, 1, DotPos) + NewExt
   Else
    VFD_InputText := VFD_InputText + '.' + NewExt;
   VFD_InputCursor := Length(VFD_InputText);
  End;
 End;
 VFDFilterEnsureVisible;
 VFDLoadDirectory;
End;

Procedure VFDCycleFilter;
Begin
 If VFD_FilterCount = 0 Then Exit;
 VFDApplyFilter((VFD_FilterIndex + 1) Mod VFD_FilterCount);
End;

{ Valide la selection courante. Retourne True si on doit fermer le dialogue }
Function VFDAccept: Boolean;
Var Full: String;
Begin
 VFDAccept := False;
 { Si une ligne est selectionnee et c'est un repertoire : naviguer }
 If (VFD_SelIndex >= 0) And (VFD_SelIndex < VFD_FileCount) And
    VFD_Files[VFD_SelIndex].IsDir Then Begin
  VFDEnterDir(VFD_Files[VFD_SelIndex].Name);
  VFD_InputText := '';
  VFD_InputCursor := 0;
  Exit;
 End;
 { Sinon, prendre VFD_InputText }
 If Length(VFD_InputText) = 0 Then Exit;
 { Si le texte contient un chemin absolu ou relatif, le traiter }
 If (Length(VFD_InputText) >= 2) And (VFD_InputText[2] = ':') Then
  Full := VFD_InputText
 Else If (Length(VFD_InputText) > 0) And
         ((VFD_InputText[1] = '\') Or (VFD_InputText[1] = '/')) Then
  Full := Copy(VFD_CurrentPath, 1, 2) + VFD_InputText
 Else
  Full := VFD_CurrentPath + VFD_InputText;
 VFD_SelectedFile := Full;
 VFD_Result := 1;
 VFDAccept := True;
End;

{ Boucle modale du dialogue. Retourne True si OK, False si Annuler }
Function VFDRun: Boolean;
Var
 Key: Char;
 MX, MY: Integer;
 MB: LongInt;
 PrevMB: LongInt;
 Idx: Integer;
 NeedRedraw: Boolean;
 MXL, MYL: LongInt;
Begin
 PrevMB := 0;
 NeedRedraw := True;
 HideMouse;
 VFDDraw;
 ShowMouse;
 Repeat
  If NeedRedraw Then Begin
   HideMouse;
   VFDDraw;
   ShowMouse;
   NeedRedraw := False;
  End;

  { ----- Clavier ----- }
  If KeyPressed Then Begin
   Key := ReadKey;
   If Key = #27 Then Begin
    If VFD_FilterOpen Then Begin
     VFD_FilterOpen := False;
     NeedRedraw := True;
    End Else Begin
     VFD_Result := 2;
     Break;
    End;
   End
   Else If Key = #13 Then Begin
    If VFD_FilterOpen Then Begin
     VFDApplyFilter(VFD_FilterIndex);
     VFD_FilterOpen := False;
     NeedRedraw := True;
    End Else Begin
     If VFDAccept Then Break;
     NeedRedraw := True;
    End;
   End
   Else If Key = #8 Then Begin
    If (VFD_InputCursor > 0) And (Length(VFD_InputText) > 0) Then Begin
     Delete(VFD_InputText, VFD_InputCursor, 1);
     Dec(VFD_InputCursor);
     NeedRedraw := True;
    End;
   End
   Else If Key = #9 Then Begin
    { Tab : ouvrir / cycler filtre }
    If VFD_FilterOpen Then Begin
     If VFD_FilterCount > 0 Then Begin
      VFD_FilterIndex := (VFD_FilterIndex + 1) Mod VFD_FilterCount;
      VFDFilterEnsureVisible;
     End;
    End Else
     VFDCycleFilter;
    NeedRedraw := True;
   End
   Else If Key = #0 Then Begin
    Key := ReadKey;
    If VFD_FilterOpen Then Begin
     Case Key Of
      #72: { Up } If VFD_FilterIndex > 0 Then Begin
                   Dec(VFD_FilterIndex); VFDFilterEnsureVisible;
                   NeedRedraw := True;
                  End;
      #80: { Down } If VFD_FilterIndex < VFD_FilterCount - 1 Then Begin
                     Inc(VFD_FilterIndex); VFDFilterEnsureVisible;
                     NeedRedraw := True;
                    End;
      #73: { PgUp } Begin
                     VFD_FilterIndex := VFD_FilterIndex
                                          - VFDFilterListVisible;
                     If VFD_FilterIndex < 0 Then VFD_FilterIndex := 0;
                     VFDFilterEnsureVisible; NeedRedraw := True;
                    End;
      #81: { PgDn } Begin
                     VFD_FilterIndex := VFD_FilterIndex
                                          + VFDFilterListVisible;
                     If VFD_FilterIndex >= VFD_FilterCount Then
                      VFD_FilterIndex := VFD_FilterCount - 1;
                     VFDFilterEnsureVisible; NeedRedraw := True;
                    End;
      #71: { Home } Begin
                     VFD_FilterIndex := 0;
                     VFDFilterEnsureVisible; NeedRedraw := True;
                    End;
      #79: { End } Begin
                    If VFD_FilterCount > 0 Then
                     VFD_FilterIndex := VFD_FilterCount - 1;
                    VFDFilterEnsureVisible; NeedRedraw := True;
                   End;
     End;
    End Else
    Case Key Of
     #72: Begin { Fleche haut }
           If VFD_SelIndex > 0 Then Begin
            Dec(VFD_SelIndex);
            If VFD_SelIndex < VFD_ScrollTop Then
             VFD_ScrollTop := VFD_SelIndex;
            If Not VFD_Files[VFD_SelIndex].IsDir Then Begin
             VFD_InputText := VFD_Files[VFD_SelIndex].Name;
             VFD_InputCursor := Length(VFD_InputText);
            End;
            NeedRedraw := True;
           End;
          End;
     #80: Begin { Fleche bas }
           If VFD_SelIndex < VFD_FileCount - 1 Then Begin
            Inc(VFD_SelIndex);
            If VFD_ListVisible > 0 Then
             If VFD_SelIndex >= VFD_ScrollTop + VFD_ListVisible Then
              VFD_ScrollTop := VFD_SelIndex - VFD_ListVisible + 1;
            If Not VFD_Files[VFD_SelIndex].IsDir Then Begin
             VFD_InputText := VFD_Files[VFD_SelIndex].Name;
             VFD_InputCursor := Length(VFD_InputText);
            End;
            NeedRedraw := True;
           End Else If VFD_FileCount > 0 Then Begin
            VFD_SelIndex := 0;
            VFD_ScrollTop := 0;
            NeedRedraw := True;
           End;
          End;
     #73: Begin { PgUp }
           If VFD_ListVisible > 0 Then Begin
            VFD_SelIndex := VFD_SelIndex - VFD_ListVisible;
            If VFD_SelIndex < 0 Then VFD_SelIndex := 0;
            VFD_ScrollTop := VFD_ScrollTop - VFD_ListVisible;
            If VFD_ScrollTop < 0 Then VFD_ScrollTop := 0;
            NeedRedraw := True;
           End;
          End;
     #81: Begin { PgDn }
           If VFD_ListVisible > 0 Then Begin
            VFD_SelIndex := VFD_SelIndex + VFD_ListVisible;
            If VFD_SelIndex >= VFD_FileCount Then
             VFD_SelIndex := VFD_FileCount - 1;
            VFD_ScrollTop := VFD_ScrollTop + VFD_ListVisible;
            If VFD_ScrollTop + VFD_ListVisible > VFD_FileCount Then
             VFD_ScrollTop := VFD_FileCount - VFD_ListVisible;
            If VFD_ScrollTop < 0 Then VFD_ScrollTop := 0;
            NeedRedraw := True;
           End;
          End;
     #71: Begin { Home }
           VFD_SelIndex := 0;
           VFD_ScrollTop := 0;
           NeedRedraw := True;
          End;
     #79: Begin { End }
           If VFD_FileCount > 0 Then Begin
            VFD_SelIndex := VFD_FileCount - 1;
            If VFD_ListVisible > 0 Then Begin
             VFD_ScrollTop := VFD_FileCount - VFD_ListVisible;
             If VFD_ScrollTop < 0 Then VFD_ScrollTop := 0;
            End;
            NeedRedraw := True;
           End;
          End;
     #75: Begin { Fleche gauche : curseur saisie }
           If VFD_InputCursor > 0 Then Begin
            Dec(VFD_InputCursor); NeedRedraw := True;
           End;
          End;
     #77: Begin { Fleche droite : curseur saisie }
           If VFD_InputCursor < Length(VFD_InputText) Then Begin
            Inc(VFD_InputCursor); NeedRedraw := True;
           End;
          End;
    End;
   End
   Else If (Key >= ' ') And (Key <= '~') Then Begin
    If Length(VFD_InputText) < 127 Then Begin
     Inc(VFD_InputCursor);
     Insert(Key, VFD_InputText, VFD_InputCursor);
     NeedRedraw := True;
    End;
   End;
  End;

  { ----- Souris ----- }
  {$IFDEF FPC}
   GetMouseState(MXL, MYL, MB);
   MX := MXL; MY := MYL;
  {$ELSE}
   GetMouseState(MX, MY, MB);
  {$ENDIF}
  { Rising edge : bouton gauche presse }
  If ((MB And 1) = 1) And ((PrevMB And 1) = 0) Then Begin
   { Si le drop-down filtre est ouvert, traiter ses clics en priorite }
   If VFD_FilterOpen Then Begin
    If VFDHitFilterArrowUp(MX, MY) Then Begin
     If VFD_FilterScrollTop > 0 Then Dec(VFD_FilterScrollTop);
     NeedRedraw := True;
     PrevMB := MB; Continue;
    End;
    If VFDHitFilterArrowDown(MX, MY) Then Begin
     If VFD_FilterScrollTop + VFDFilterListVisible < VFD_FilterCount Then
      Inc(VFD_FilterScrollTop);
     NeedRedraw := True;
     PrevMB := MB; Continue;
    End;
    If VFDHitFilterTrack(MX, MY) Then Begin
     { Page-scroll dans la piste }
     Idx := VFDFilterListVisible;
     If MY < VFD_Y + VFD_H Then Begin
      If VFD_FilterScrollTop > Idx Then Dec(VFD_FilterScrollTop, Idx)
                                    Else VFD_FilterScrollTop := 0;
     End;
     NeedRedraw := True;
     PrevMB := MB; Continue;
    End;
    Idx := VFDHitFilterRow(MX, MY);
    If Idx >= 0 Then Begin
     VFDApplyFilter(Idx);
     VFD_FilterOpen := False;
     NeedRedraw := True;
     PrevMB := MB; Continue;
    End;
    { Clic sur le combo lui-meme = referme }
    If VFDHitFilter(MX, MY) Then Begin
     VFD_FilterOpen := False;
     NeedRedraw := True;
     PrevMB := MB; Continue;
    End;
    { Clic n'importe ou ailleurs : fermer le drop-down ET ne pas
      traiter le clic comme une action normale }
    VFD_FilterOpen := False;
    NeedRedraw := True;
    PrevMB := MB; Continue;
   End;

   { Bouton fermer dans la barre titre }
   If VFDHitClose(MX, MY) Then Begin
    VFD_Result := 2; PrevMB := MB; Break;
   End;

   { Boutons OK / Cancel }
   Idx := VFDHitButton(MX, MY);
   If Idx = 0 Then Begin
    If VFDAccept Then Break;
    NeedRedraw := True;
   End
   Else If Idx = 1 Then Begin
    VFD_Result := 2; PrevMB := MB; Break;
   End;

   { Selecteur de filtre : ouvrir la liste deroulante }
   If VFDHitFilter(MX, MY) Then Begin
    VFD_FilterOpen := True;
    VFDFilterEnsureVisible;
    NeedRedraw := True;
    PrevMB := MB; Continue;
   End;

   { Barre lecteurs }
   Idx := VFDHitDrive(MX, MY);
   If Idx > 0 Then Begin
    VFDChangeDrive(Idx);
    NeedRedraw := True;
   End;

   { Liste de fichiers : un seul clic suffit (rep = navigue, fichier = selec) }
   Idx := VFDHitList(MX, MY);
   If Idx >= 0 Then Begin
    If VFD_Files[Idx].IsDir Then Begin
     VFDEnterDir(VFD_Files[Idx].Name);
     VFD_InputText := '';
     VFD_InputCursor := 0;
    End Else Begin
     VFD_SelIndex := Idx;
     VFD_InputText := VFD_Files[Idx].Name;
     VFD_InputCursor := Length(VFD_InputText);
    End;
    NeedRedraw := True;
   End;
  End;
  PrevMB := MB;
 Until False;

 If VFD_Result = 1 Then VFDRun := True
                   Else VFDRun := False;
End;

{ Point d'entree externe : affiche le dialogue et renvoie le chemin choisi }
Function ShowVisioFileDialog(SaveMode: Boolean;
                             Const DefaultName: String;
                             Var ChosenFile: String): Boolean;
Var Title: String;
Begin
 VFD_ExportMode := False;
 If SaveMode Then Begin
  If Language = _English Then Title := 'Save Visio document as'
                        Else Title := 'Enregistrer le document Visio sous';
 End Else Begin
  If Language = _English Then Title := 'Open Visio document'
                        Else Title := 'Ouvrir un document Visio';
 End;
 VFDInit(Title, SaveMode, DefaultName);
 If VFDRun Then Begin
  ChosenFile := VFD_SelectedFile;
  ShowVisioFileDialog := True;
 End Else Begin
  ChosenFile := '';
  ShowVisioFileDialog := False;
 End;
End;

{ Retourne l'extension principale du filtre courant (sans le point), ou '' }
Function VFDFilterPrimaryExt: String;
Var P, E: String; I: Integer;
Begin
 VFDFilterPrimaryExt := '';
 If (VFD_FilterIndex < 0) Or (VFD_FilterIndex >= VFD_FilterCount) Then Exit;
 P := VFD_Filters[VFD_FilterIndex].Pattern;
 I := Pos('*.', P);
 If I = 0 Then Exit;
 E := Copy(P, I + 2, Length(P));
 I := 1;
 While (I <= Length(E)) And (E[I] <> ';') And (E[I] <> ',') And
       (E[I] <> ' ') And (E[I] <> ')') Do Inc(I);
 E := Copy(E, 1, I - 1);
 If E = '*' Then E := '';
 { Uppercase }
 For I := 1 To Length(E) Do
  If (E[I] >= 'a') And (E[I] <= 'z') Then E[I] := Chr(Ord(E[I]) - 32);
 VFDFilterPrimaryExt := E;
End;

{ Variante Export : meme dialogue mais avec la liste des formats d'export. }
{ Retourne aussi l'extension primaire du filtre choisi (utile si l'utilisateur }
{ a tape un nom sans extension).                                             }
Function ShowVisioExportDialog(Const DefaultName: String;
                               Var ChosenFile: String;
                               Var SelectedExt: String): Boolean;
Var Title: String;
Begin
 VFD_ExportMode := True;
 If Language = _English Then Title := 'Export drawing as'
                       Else Title := 'Exporter le dessin sous';
 VFDInit(Title, True, DefaultName);
 If VFDRun Then Begin
  ChosenFile := VFD_SelectedFile;
  SelectedExt := VFDFilterPrimaryExt;
  ShowVisioExportDialog := True;
 End Else Begin
  ChosenFile := '';
  SelectedExt := '';
  ShowVisioExportDialog := False;
 End;
 VFD_ExportMode := False;
End;

{ ============================================================================ }
{ === FIN BOITE DE DIALOGUE FICHIER ========================================== }
{ ============================================================================ }

{ ProcÃ©dure pour initialiser le systÃ¨me de menus }
Procedure InitMenuSystem;
Begin
 CurrentMenu := 0;
 MenuState := msNone;
 HoveredMenuItem := 0;
 OldHoveredMenuItem := 0;
 PrevMouseX := -1;
 PrevMouseY := -1;
 StatusMessage := '';

 { Localisation des noms et positions de la barre de menu.
   Defaut = anglais (deja en typed const). Si Language <> _English,
   on bascule en francais. }
 If Language <> _English Then Begin
  MenuNames[1] := 'Fichier';
  MenuNames[2] := 'Edition';
  MenuNames[3] := 'Affichage';
  MenuNames[4] := 'Insertion';
  MenuNames[5] := 'Format';
  MenuNames[6] := 'Forme';
  MenuNames[7] := 'Outils';
  MenuNames[8] := 'Fenetre';
  MenuNames[9] := 'Aide';
  MenuPositions[1] := 5;
  MenuPositions[2] := 70;
  MenuPositions[3] := 135;
  MenuPositions[4] := 215;
  MenuPositions[5] := 295;
  MenuPositions[6] := 350;
  MenuPositions[7] := 400;
  MenuPositions[8] := 455;
  MenuPositions[9] := 520;
 End;

 ScreenWidth := GetMaxX;
 ScreenHeight := GetMaxY;
 CurrentFileName := '';
 DocumentModified := False;
 { Initialisation des variables du menu Edit }
 UndoStackIndex := 0;
 CanUndo := False;
 CanRedo := False;
 ClipboardEmpty := True;
 HasSelection := False;
 { Initialisation des variables du menu View }
 ZoomLevel := DEFAULT_ZOOM;
 ShowGrid := False;
 ShowRulers := True;
 ShowGuides := True;
 SnapToGridEnabled := True;
 { Initialisation des variables du menu Insert }
 CurrentPage := 1;
 PageCount := DEFAULT_PAGE_COUNT;
 CurrentLayer := 1;
 LayerCount := DEFAULT_LAYER_COUNT;
 InsertMode := 0;
 { Initialisation des variables du menu Format }
 CurrentFillColor := DEFAULT_FILL_COLOR;
 CurrentLineColor := DEFAULT_LINE_COLOR;
 CurrentLineWidth := DEFAULT_LINE_WIDTH;
 CurrentLineStyle := DEFAULT_LINE_STYLE;
 CurrentTextSize := DEFAULT_TEXT_SIZE;
 CurrentAlignment := atLeft;
 ObjectsGrouped := False;
 { Initialisation des variables de gestion des groupes }
 NextGroupID := 0;
 EditingGroupID := 0;
 { Initialisation des variables de la boÃ®te de dialogue des propriÃ©tÃ©s }
 PropertiesDialogVisible := False;
 PropDialogX := 0;
 PropDialogY := 0;
 PropSelectedColor := 0;
 PropSelectedLineWidth := 1;
 PropSelectedLineStyle := LINESTYLE_SOLID;
 PropHighlightedButton := 0;
 { Initialisation des variables du menu Shape }
 CurrentRotation := 0;
 ShapeWidth := 100;
 ShapeHeight := 100;
 ShapeX := 0;
 ShapeY := 0;
 { Initialisation de la barre d'outils }
 CurrentTool := ttSelection;
End;

{ Fonction pour exÃ©cuter une action du menu File }
{ Retourne True si l'application doit quitter }
Function ExecuteFileMenuAction(ItemIndex: Integer): Boolean;
Begin
 ExecuteFileMenuAction := False;
 Case ItemIndex of
  1: FileNew;           { New }
  2: FileOpen;          { Open... }
  3: FileClose;         { Close }
  4: FileSave;          { Save }
  5: FileSaveAs;        { Save As... }
  { 6 est un sÃ©parateur }
  7: FileExport;        { Export... }
  { 8 est un sÃ©parateur }
  9: FilePrint;         { Print... }
  10: FilePrintPreview; { Print Preview }
  11: ExecuteFileMenuAction := FileExit; { Exit }
 End;
End;

{ Action declenchee par un clic sur un bouton de la barre d'icones }
Procedure ExecuteIconBarAction(Index: Integer);
Begin
 Case Index of
  1: FileNew;       { Nouveau }
  2: FileOpen;      { Ouvrir }
  3: FileSave;      { Enregistrer }
  5: FilePrint;     { Imprimer }
  7: EditUndo;      { Annuler }
  8: EditRedo;      { Retablir }
 End;
End;

{ ProcÃ©dure pour exÃ©cuter une action du menu Edit }
Procedure ExecuteEditMenuAction(ItemIndex: Integer);
Begin
 Case ItemIndex of
  1: EditUndo;         { Undo }
  2: EditRedo;         { Redo }
  { 3 est un sÃ©parateur }
  4: EditCut;          { Cut }
  5: EditCopy;         { Copy }
  6: EditPaste;        { Paste }
  7: EditDelete;       { Delete }
  { 8 est un sÃ©parateur }
  9: EditSelectAll;    { Select All }
  { 10 est un sÃ©parateur }
  11: EditFind;        { Find... }
  12: EditReplace;     { Replace... }
 End;
End;

{ ProcÃ©dure pour exÃ©cuter une action du menu View }
Procedure ExecuteViewMenuAction(ItemIndex: Integer);
Begin
 Case ItemIndex of
  1: ViewZoomIn;       { Zoom In }
  2: ViewZoomOut;      { Zoom Out }
  3: ViewFitPage;      { Fit Page }
  { 4 est un sÃ©parateur }
  5: ViewGrid;         { Grid }
  6: ViewRulers;       { Rulers }
  7: ViewGuides;       { Guides }
  { 8 est un sÃ©parateur }
  9: ViewSnapToGrid;   { Snap to Grid }
 End;
End;

{ ProcÃ©dure pour exÃ©cuter une action du menu Insert }
Procedure ExecuteInsertMenuAction(ItemIndex: Integer);
Begin
 Case ItemIndex of
  1: InsertShape;      { Shape }
  2: InsertTextBox;    { Text Box }
  3: InsertImage;      { Image... }
  4: InsertConnector;  { Connector }
  5: InsertPage;       { Page }
  6: ShowLayerDialog;  { Layer - Ouvrir la boÃ®te de dialogue des calques }
 End;
End;

{ ProcÃ©dure pour exÃ©cuter une action du menu Format }
Procedure ExecuteFormatMenuAction(ItemIndex: Integer);
Begin
 Case ItemIndex of
  1: FormatFill;       { Fill... }
  2: FormatLine;       { Line... }
  3: FormatText;       { Text... }
  { 4 est un sÃ©parateur }
  5: FormatAlignment;  { Alignment }
  6: FormatGroup;      { Group }
  7: FormatUngroup;    { Ungroup }
 End;
End;

{ ProcÃ©dure pour exÃ©cuter une action du menu Shape }
Procedure ExecuteShapeMenuAction(ItemIndex: Integer);
Begin
 Case ItemIndex of
  1: ShapeRotate;      { Rotate }
  2: ShapeFlip;        { Flip }
  { 3 est un sÃ©parateur }
  4: ShapeAlign;       { Align }
  5: ShapeDistribute;  { Distribute }
  { 6 est un sÃ©parateur }
  7: ShapeSize;        { Size }
  8: ShapePosition;    { Position }
  { 9 est un sÃ©parateur }
  10: ShapeOperations; { Operations }
 End;
End;

{ Fonction pour dÃ©terminer quel Ã©lÃ©ment de menu est sous la souris }
Function GetDropDownItemAtPosition(MenuIndex, MouseX, MouseY: Integer): Integer;
Const
 ItemHeight = 16;
 MenuWidth = 260;
Var
 X, Y, ItemCount, I: Integer;
Begin
 GetDropDownItemAtPosition := 0;

 { DÃ©terminer le nombre d'Ã©lÃ©ments selon le menu }
 Case MenuIndex of
  1: ItemCount := 11; { File }
  2: ItemCount := 12; { Edit }
  3: ItemCount := 9;  { View }
  4: ItemCount := 6;  { Insert }
  5: ItemCount := 7;  { Format }
  6: ItemCount := 10; { Shape }
  7: ItemCount := 4;  { Tools }
  8: ItemCount := 4;  { Window }
  9: ItemCount := 3;  { Help }
  Else ItemCount := 0;
 End;

 If ItemCount = 0 Then Exit;

 { Calculer la position du menu dÃ©roulant }
 X := MenuPositions[MenuIndex] - 4;
 Y := MENU_HEIGHT + 1;

 { VÃ©rifier si la souris est dans la zone du menu dÃ©roulant }
 If (MouseX >= X) and (MouseX <= X + MenuWidth) and
    (MouseY >= Y) and (MouseY <= Y + ItemCount * ItemHeight + 4) Then Begin
  { Calculer l'Ã©lÃ©ment sous la souris }
  I := (MouseY - Y) div ItemHeight + 1;
  If (I >= 1) and (I <= ItemCount) Then Begin
   GetDropDownItemAtPosition := I;
  End;
 End;
End;

{ Wrapper : PtcMouse.GetMouseState exige des LongInt par var en FPC }
Procedure GetMouseStateInt(Var MX, MY: Integer; Var MB: LongInt);
Var
 LX, LY: LongInt;
Begin
 GetMouseState(LX, LY, MB);
 MX := LX;
 MY := LY;
End;

{ ProcÃ©dure pour rafraÃ®chir l'affichage complet }
Procedure RefreshScreen;
Begin
 { Effacer l'Ã©cran avec fond blanc (zone de travail sous la barre d'outils) }
 SetFillStyle(SolidFill, White);
 Bar(TOOLBAR_WIDTH + 1, MENU_HEIGHT + 1, ScreenWidth, ScreenHeight);

 { Dessiner tous les objets graphiques }
 DrawAllShapes;

 { Dessiner la barre de menu }
 DrawMenuBar;

 { Dessiner la barre d'icones horizontale }
 DrawIconBar;

 { Dessiner la barre d'outils }
 DrawToolbar;

 { Si un menu est ouvert, le dessiner }
 If (MenuState = msDropDown) and (CurrentMenu > 0) Then Begin
  DrawDropDownMenu(CurrentMenu);
 End;

 { Dessiner le menu contextuel s'il est visible }
 If ContextMenuVisible Then Begin
  DrawContextMenu;
 End;

 { Dessiner la boÃ®te de dialogue des propriÃ©tÃ©s si elle est visible }
 If PropertiesDialogVisible Then Begin
  DrawPropertiesDialog;
 End;

 { Dessiner la boÃ®te de dialogue des calques si elle est visible }
 If LayerDialogVisible Then Begin
  DrawLayerDialog;
 End;

 { Barre d'etat : afficher le dernier message d'action }
 If StatusMessage <> '' Then Begin
  SetFillStyle(SolidFill, LightGray);
  Bar(0, ScreenHeight - 16, ScreenWidth, ScreenHeight);
  SetColor(DarkGray);
  Line(0, ScreenHeight - 16, ScreenWidth, ScreenHeight - 16);
  SetColor(Black);
  OutTextXY(6, ScreenHeight - 12, StatusMessage);
 End;
End;

BEGIN
 { Initialiser la langue }
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='SQ')or
    (StrToUpper(Copy(TmpLanguage,1,3))='ALB')Then Language:=_Albanian Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='PT')or
    (StrToUpper(Copy(TmpLanguage,1,3))='PRT')Then Language:=_Portuguese Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='SE')or
    (StrToUpper(Copy(TmpLanguage,1,3))='SWE')Then Language:=_Swedish Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='DK')or
    (StrToUpper(Copy(TmpLanguage,1,3))='DNK')Then Language:=_Danish Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='JP')or
    (StrToUpper(Copy(TmpLanguage,1,3))='JPN')Then Language:=_Japanese;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('VISIO : Cette commande permet de lancer un clone de Visio.');
  WriteLn;
  WriteLn('Syntaxe : VISIO [image.VSDX]');
  WriteLn;
  WriteLn(' image.VSDX       Nom du fichier ".VSDX" a editer');
  Halt;
 End;
 InitializeGraphics;
 InitMenuSystem;
 InitShapes;
 InitContextMenu;
 { Si un nom de fichier est passe en ligne de commande, l'ouvrir }
 If ParamCount >= 1 Then Begin
  CurrentFileName := ParamStr(1);
  If LoadVisioFile(CurrentFileName) Then Begin
   DocumentModified := False;
   SelectedShape := 0;
   If Language = _English Then
    StatusMessage := 'Opened: ' + CurrentFileName
   Else
    StatusMessage := 'Ouvert : ' + CurrentFileName;
  End Else Begin
   If Language = _English Then
    StatusMessage := 'Open failed: ' + CurrentFileName
   Else
    StatusMessage := 'Echec ouverture : ' + CurrentFileName;
   CurrentFileName := '';
  End;
 End;

 { Afficher l'Ã©cran initial avec le menu }
 RefreshScreen;

 { Boucle principale - en attente d'une touche pour quitter }
 If MouseDriverFound Then Begin
  ShowMouse;
 End;

 { Boucle principale du programme }
 Repeat
  { GÃ©rer les Ã©vÃ©nements de la souris }
  If MouseDriverFound Then Begin
   {$IFDEF FPC}
    GetMouseStateInt(LastMouseX, LastMouseY, LastMouseButton);
   {$ELSE}
    GetMouseState(LastMouseX, LastMouseY, LastMouseButton);
   {$ENDIF}

   { DÃ©tecter le survol des poignÃ©es de redimensionnement }
   If (SelectedShape > 0) and (DragMode = DRAG_MODE_NONE) Then Begin
    OldHoveredHandle := HoveredHandle;
    HoveredHandle := GetResizeHandle(LastMouseX, LastMouseY, SelectedShape);
    { Si le survol a changÃ©, rafraÃ®chir l'Ã©cran }
    If HoveredHandle <> OldHoveredHandle Then Begin
     HideMouse;
     RefreshScreen;
     ShowMouse;
    End;
   End
   Else Begin
    HoveredHandle := RESIZE_HANDLE_NONE;
   End;

   { Detecter le survol des items du menu deroulant.
     N'agir QUE si la souris a reellement bouge, sinon les fleches du
     clavier sont ecrasees a chaque iteration. Comportement style PAINT.PAS :
     si la souris glisse sur un autre nom de menu dans la barre, basculer
     le menu deroulant sur ce menu. }
   If (MenuState = msDropDown) and (CurrentMenu > 0) and
      ((LastMouseX <> PrevMouseX) or (LastMouseY <> PrevMouseY)) Then Begin
    HoveredMenuOnBar := GetMenuAtPosition(LastMouseX, LastMouseY);
    If (HoveredMenuOnBar > 0) and (HoveredMenuOnBar <> CurrentMenu) Then Begin
     CurrentMenu := HoveredMenuOnBar;
     HoveredMenuItem := 0;
     HideMouse;
     RefreshScreen;
     ShowMouse;
    End
    Else Begin
     OldHoveredMenuItem := HoveredMenuItem;
     HoveredMenuItem := GetDropDownItemAtPosition(CurrentMenu,
                                                   LastMouseX, LastMouseY);
     If HoveredMenuItem <> OldHoveredMenuItem Then Begin
      HideMouse;
      RefreshScreen;
      ShowMouse;
     End;
    End;
   End;
   PrevMouseX := LastMouseX;
   PrevMouseY := LastMouseY;

   { DÃ©tecter le survol des formes pour afficher les points d'ancrage (outil connecteur) }
   If (CurrentTool = ttConnector) and (DragMode = DRAG_MODE_NONE) Then Begin
    { Trouver la forme sous la souris }
    HoveredShapeForAnchor := GetShapeAtPosition(LastMouseX, LastMouseY);
    { Trouver le point d'ancrage le plus proche si on survole une forme }
    If HoveredShapeForAnchor > 0 Then Begin
     If Not FindNearestAnchor(LastMouseX, LastMouseY, HoveredShapeForAnchor, NearestAnchorPoint) Then
      NearestAnchorPoint := ANCHOR_NONE;
    End
    Else Begin
     NearestAnchorPoint := ANCHOR_NONE;
    End;
   End
   Else Begin
    HoveredShapeForAnchor := 0;
    NearestAnchorPoint := ANCHOR_NONE;
   End;

   { DÃ©tecter un clic gauche (bouton 1) }
   If (LastMouseButton and 1) = 1 Then Begin
    HideMouse;
    { Si la boÃ®te de dialogue des calques est visible, gÃ©rer le clic }
    If LayerDialogVisible Then Begin
     HandleLayerDialogClick(LastMouseX, LastMouseY);
    End
    { Si la boÃ®te de dialogue des propriÃ©tÃ©s est visible, gÃ©rer le clic }
    Else If PropertiesDialogVisible Then Begin
     HandlePropertiesDialogClick(LastMouseX, LastMouseY);
    End
    { Si le menu contextuel est visible, vÃ©rifier si on clique dedans }
    Else If ContextMenuVisible Then Begin
     ContextMenuHighlight := GetContextMenuItemAtPosition(LastMouseX, LastMouseY);
     If ContextMenuHighlight > 0 Then Begin
      ExecuteContextMenuAction(ContextMenuHighlight);
     End
     Else Begin
      { Clic en dehors du menu contextuel, le fermer }
      HideContextMenu;
     End;
    End
    Else Begin
     HandleLeftClick(LastMouseX, LastMouseY);
    End;
    RefreshScreen;
    ShowMouse;
    { Suivre le mouvement de la souris pendant que le bouton est enfoncÃ© (drag) }
    Repeat
     {$IFDEF FPC}
      GetMouseStateInt(LastMouseX, LastMouseY, LastMouseButton);
     {$ELSE}
      GetMouseState(LastMouseX, LastMouseY, LastMouseButton);
     {$ENDIF}
     { Si on est en mode glissement, mettre Ã  jour la position }
     If DragMode <> DRAG_MODE_NONE Then Begin
      HideMouse;
      HandleMouseMove(LastMouseX, LastMouseY);
      RefreshScreen;
      ShowMouse;
     End
     Else If IsDrawing And
            ((CurrentTool = ttRectangle) Or (CurrentTool = ttEllipse) Or
             (CurrentTool = ttLine) Or (CurrentTool = ttConnector))
     Then Begin
      HideMouse;
      If (Not PreviewValid) Or
         (PreviewX2 <> LastMouseX) Or (PreviewY2 <> LastMouseY) Then
       UpdatePreview(CurrentTool, DrawStartX, DrawStartY,
                     LastMouseX, LastMouseY)
      Else Begin
       Inc(PreviewBlinkTick);
       If (PreviewBlinkTick And $1F) = 0 Then BlinkPreview;
      End;
      ShowMouse;
     End;
    Until (LastMouseButton and 1) = 0;
    { GÃ©rer le relÃ¢chement du bouton }
    HideMouse;
    ClearPreview;
    HandleLeftRelease(LastMouseX, LastMouseY);
    RefreshScreen;
    ShowMouse;
   End;

   { DÃ©tecter un clic droit (bouton 2) }
   If (LastMouseButton and 2) = 2 Then Begin
    HideMouse;
    HandleRightClick(LastMouseX, LastMouseY);
    RefreshScreen;
    ShowMouse;
    { Attendre que le bouton soit relÃ¢chÃ© }
    Repeat
     {$IFDEF FPC}
      GetMouseStateInt(LastMouseX, LastMouseY, LastMouseButton);
     {$ELSE}
      GetMouseState(LastMouseX, LastMouseY, LastMouseButton);
     {$ENDIF}
    Until (LastMouseButton and 2) = 0;
   End;
  End;

  { Attendre une entrÃ©e clavier }
  If KeyPressed Then Begin
   MainLoopKey := ReadKey;
   { Si un menu deroulant est ouvert, intercepter Enter/Esc/fleches }
   If (MenuState = msDropDown) and (CurrentMenu > 0) Then Begin
    If MainLoopKey = #13 Then Begin
     { Enter : activer l'element survole }
     If (HoveredMenuItem >= 1) and
        (HoveredMenuItem <= GetMenuItemCount(CurrentMenu)) and
        Not IsMenuSeparator(CurrentMenu, HoveredMenuItem) Then Begin
      Case CurrentMenu of
       1: Begin
           MainLoopExit := ExecuteFileMenuAction(HoveredMenuItem);
           If MainLoopExit Then Halt;
          End;
       2: ExecuteEditMenuAction(HoveredMenuItem);
       3: ExecuteViewMenuAction(HoveredMenuItem);
       4: ExecuteInsertMenuAction(HoveredMenuItem);
       5: ExecuteFormatMenuAction(HoveredMenuItem);
       6: ExecuteShapeMenuAction(HoveredMenuItem);
      End;
      MenuState := msNone;
      CurrentMenu := 0;
      HoveredMenuItem := 0;
      RefreshScreen;
     End;
    End
    Else If MainLoopKey = #27 Then Begin
     { Esc : fermer le menu }
     MenuState := msNone;
     CurrentMenu := 0;
     HoveredMenuItem := 0;
     RefreshScreen;
    End
    Else If MainLoopKey = #0 Then Begin
     MainLoopKey := ReadKey;
     Case MainLoopKey of
      #72: Begin { fleche haut - element precedent (saute les separateurs) }
            If HoveredMenuItem <= 0 Then
             HoveredMenuItem := GetMenuItemCount(CurrentMenu) + 1;
            Repeat
             Dec(HoveredMenuItem);
             If HoveredMenuItem < 1 Then
              HoveredMenuItem := GetMenuItemCount(CurrentMenu);
            Until Not IsMenuSeparator(CurrentMenu, HoveredMenuItem);
            RefreshScreen;
           End;
      #80: Begin { fleche bas - element suivant (saute les separateurs) }
            Repeat
             Inc(HoveredMenuItem);
             If HoveredMenuItem > GetMenuItemCount(CurrentMenu) Then
              HoveredMenuItem := 1;
            Until Not IsMenuSeparator(CurrentMenu, HoveredMenuItem);
            RefreshScreen;
           End;
      #75: Begin { fleche gauche - menu precedent }
            CurrentMenu := ((CurrentMenu - 2 + MENU_COUNT) Mod MENU_COUNT) + 1;
            HoveredMenuItem := 0;
            RefreshScreen;
           End;
      #77: Begin { fleche droite - menu suivant }
            CurrentMenu := (CurrentMenu Mod MENU_COUNT) + 1;
            HoveredMenuItem := 0;
            RefreshScreen;
           End;
     End;
    End;
   End
   Else Begin
    { Aucun menu deroulant ouvert : comportement habituel }
    Case MainLoopKey of
     #27: Begin
           { Si le menu contextuel est visible, le fermer }
           If ContextMenuVisible Then Begin
            HideContextMenu;
            RefreshScreen;
           End
           Else Begin
            Break; { Escape pour quitter }
           End;
          End;
     #1:  Begin EditSelectAll; RefreshScreen; End;  { Ctrl+A }
     #3:  Begin EditCopy;      RefreshScreen; End;  { Ctrl+C }
     #6:  Begin EditFind;      RefreshScreen; End;  { Ctrl+F }
     #14: Begin FileNew;       RefreshScreen; End;  { Ctrl+N }
     #15: Begin FileOpen;      RefreshScreen; End;  { Ctrl+O }
     #16: Begin FilePrint;     RefreshScreen; End;  { Ctrl+P }
     #19: Begin FileSave;      RefreshScreen; End;  { Ctrl+S }
     #22: Begin EditPaste;     RefreshScreen; End;  { Ctrl+V }
     #23: Begin FileClose;     RefreshScreen; End;  { Ctrl+W }
     #24: Begin EditCut;       RefreshScreen; End;  { Ctrl+X }
     #25: Begin EditRedo;      RefreshScreen; End;  { Ctrl+Y }
     #26: Begin EditUndo;      RefreshScreen; End;  { Ctrl+Z }
     #0: Begin { Touches de fonction et combinaisons Alt/Shift }
          MainLoopKey := ReadKey;
          Case MainLoopKey of
           #59: Begin { F1 - Aide }
                 CurrentMenu := 9;
                 MenuState := msDropDown;
                 HoveredMenuItem := 0;
                 RefreshScreen;
                End;
           #107: Begin { Alt+F4 - Quitter }
                  If FileExit Then Halt;
                 End;
           #134: Begin { F12 - Enregistrer sous (alternative a Ctrl+Shift+S) }
                  FileSaveAs; RefreshScreen;
                 End;
           #33: Begin  { Alt+F - menu Fichier }
                 CurrentMenu := 1; MenuState := msDropDown;
                 HoveredMenuItem := 0; RefreshScreen;
                End;
           #18: Begin  { Alt+E - menu Edition }
                 CurrentMenu := 2; MenuState := msDropDown;
                 HoveredMenuItem := 0; RefreshScreen;
                End;
           #30: Begin  { Alt+A - menu Affichage }
                 CurrentMenu := 3; MenuState := msDropDown;
                 HoveredMenuItem := 0; RefreshScreen;
                End;
           #23: Begin  { Alt+I - menu Insertion }
                 CurrentMenu := 4; MenuState := msDropDown;
                 HoveredMenuItem := 0; RefreshScreen;
                End;
           #50: Begin  { Alt+M - menu Format }
                 CurrentMenu := 5; MenuState := msDropDown;
                 HoveredMenuItem := 0; RefreshScreen;
                End;
           #34: Begin  { Alt+G - menu Forme (G comme "Geometrie") }
                 CurrentMenu := 6; MenuState := msDropDown;
                 HoveredMenuItem := 0; RefreshScreen;
                End;
           #24: Begin  { Alt+O - menu Outils }
                 CurrentMenu := 7; MenuState := msDropDown;
                 HoveredMenuItem := 0; RefreshScreen;
                End;
           #49: Begin  { Alt+N - menu Fenetre }
                 CurrentMenu := 8; MenuState := msDropDown;
                 HoveredMenuItem := 0; RefreshScreen;
                End;
           #35: Begin  { Alt+H - menu Aide (Help) }
                 CurrentMenu := 9; MenuState := msDropDown;
                 HoveredMenuItem := 0; RefreshScreen;
                End;
          End;
         End;
    End;
   End;
  End;
 Until False;
 If MouseDriverFound Then Begin
  HideMouse;
 End;
 CloseGraph;
END.
