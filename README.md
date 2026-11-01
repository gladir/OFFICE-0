# OFFICE-0
Liste de commandes écrit en Pascal (Turbo Pascal et/ou Free Pascal) pour le bureau

Aperçu de 1-2-3 :

<img width="638" height="463" alt="image" src="https://github.com/user-attachments/assets/44a7ccda-5787-4814-ac00-b31c3d2256b3" />

Aperçu du clone d'Access :

<img width="638" height="475" alt="image" src="https://github.com/user-attachments/assets/975ff2d1-e9ec-4966-b614-393b2c3a2f1d" />

Aperçu du clone d'Acrobat :

<img width="636" height="476" alt="image" src="https://github.com/user-attachments/assets/31715206-7b6d-4965-914e-1e1c4ab26d54" />

Aperçu du clone d'Excel :

<img width="638" height="482" alt="image" src="https://github.com/user-attachments/assets/9f56d511-ef57-42c4-992c-2686c3056760" />

Aperçu du clone de Lotus 1-2-3 :

<img width="638" height="480" alt="image" src="https://github.com/user-attachments/assets/b4c54172-ee6f-4c4b-962b-18aa3c0a4efc" />

Aperçu du clone de OneNote :

<img width="639" height="483" alt="image" src="https://github.com/user-attachments/assets/4e432deb-f940-45b2-adb1-c91959507b79" />

Aperçu du clone de Outlook :

<img width="639" height="481" alt="image" src="https://github.com/user-attachments/assets/0b6d7013-6a94-4398-8410-9d22c5aa0d53" />

Aperçu du clone de PowerPoint :

<img width="638" height="481" alt="image" src="https://github.com/user-attachments/assets/52a715e5-36cc-46d8-a4ea-346f7db61546" />

Aperçu du clone de Project :

<img width="641" height="481" alt="image" src="https://github.com/user-attachments/assets/54f79b67-1876-437a-b47b-5acf5bc4a960" />

Aperçu du clone de Quattro :

<img width="636" height="480" alt="image" src="https://github.com/user-attachments/assets/176fbded-45d2-4237-a1c8-be85fb9871ec" />

<table>
	<tr>
		<td><img width="320" height="240" alt="image" src="https://github.com/user-attachments/assets/4f497933-e861-4aa4-9810-8f293fc8902d" /></td>
		<td><img width="320" height="240" alt="image" src="https://github.com/user-attachments/assets/92b6c2db-e448-40d5-9f4e-44f8e2bebecf" /></td>
	</tr>
</table>

Aperçu du clone de Visio :

<img width="641" height="477" alt="image" src="https://github.com/user-attachments/assets/d6ffcfca-2fd2-4146-97fb-763b3d4f3629" />

Aperçu du clone de Word :

<img width="642" height="479" alt="image" src="https://github.com/user-attachments/assets/3208cc06-676b-47c4-a09f-a85fe45563f8" />

<h2>Liste des fichiers</h2>

Voici la liste des différents fichiers proposés dans OFFICE-0 :

<table>
		<tr>
			<th>Nom</th>
			<th>Description</th>	
		</tr>
		<tr>
			<td><b>123.PAS</b></td>
			<td>Cette commande permet de lancer un clone de Lotus 1-2-3.</td>
		</tr>
    <tr>
      <td><b>3DCALC.PAS</b></td>
      <td>Cette commande permet de lancer un clone graphique de 3D-CALC+ (tableur tridimensionnel de l'Atari ST : pages, formules, statistiques, graphiques, macros).</td>
    </tr>
    <tr>
      <td><b>ACCESS.PAS</b></td>
      <td>Cette commande permet de lancer un clone de Access.</td>
    </tr>
	<tr>
		<td><b>ACROBAT.PAS</b></td>
		<td>Cette commande permet de lancer un clone d'Acrobat.</td>
	</tr>	
	<tr>
		<td><b>EXCEL.PAS</b></td>
		<td>Cette commande permet de lancer un clone de Excel.</td>
	</tr>
    <tr>
      <td><b>LOTUS123.PAS</b></td>
      <td>Cette commande permet de lancer un clone graphique de Lotus 1-2-3 (menus, formules, graphiques 2D/3D).</td>
    </tr>
    <tr>
      <td><b>ONENOTE.PAS</b></td>
      <td>Cette commande permet de lancer un clone de OneNote.</td>
    </tr>    
    <tr>
      <td><b>OUTLOOK.PAS</b></td>
      <td>Cette commande permet de lancer un clone de Outlook.</td>
    </tr>    
    <tr>
      <td><b>POWERPNT.PAS</b></td>
      <td>Cette commande permet de lancer un clone de PowerPoint.</td>
    </tr>    
    <tr>
      <td><b>PROJECT.PAS</b></td>
      <td>Cette commande permet de lancer un clone de Project.</td>
    </tr>    
    <tr>
      <td><b>QUATTRO.PAS</b></td>
      <td>Cette commande permet de lancer un clone de Quattro Pro.</td>
    </tr>
    <tr>
      <td><b>VISIO.PAS</b></td>
      <td>Cette commande permet de lancer un clone de Visio.</td>
    </tr>    
    <tr>
      <td><b>WORD.PAS</b></td>
      <td>Cette commande permet de lancer un clone de Word.</td>
    </tr>  
</table>

<h2>Compilation</h2>
	
Les fichiers Pascal n'ont aucune dépendances, il suffit de télécharger le fichier désiré et de le compiler avec Free Pascal avec la syntaxe de commande  :

<pre><b>fpc</b> <i>LEFICHIER.PAS</i></pre>
	
Sinon, vous pouvez également le compiler avec le Turbo Pascal à l'aide de la syntaxe de commande suivante :	

<pre><b>tpc</b> <i>LEFICHIER.PAS</i></pre>
	
Par exemple, si vous voulez compiler WORD.PAS, vous devrez tapez la commande suivante :

<pre><b>fpc</b> WORD.PAS</pre>

<h2>Menus d'Excel</h2>

```bat
EXCEL /?
EXCEL /CLASSICMENU
EXCEL /RUBANMENU
EXCEL /RUBANMENU "C:\Documents\Budget 2026.xlsx"
```

Le menu classique est utilise par defaut. Les parametres sont insensibles a la
casse ; si les deux sont presents, le dernier est utilise. Le nom du classeur
peut apparaitre avant ou apres les parametres.

EXCEL /? affiche l'aide en console et quitte sans ouvrir de fenetre. Les formes
-h et --help sont egalement acceptees.

Le ruban reprend les commandes existantes avec des icones vectorielles dans des
onglets et adapte la position
de la barre de formule et de la grille. Les commandes non implementees sont
grisees. Navigation : souris, F10 ou Alt+lettre, fleches, Tab/Maj+Tab, Entree et
Echap. L'onglet Accueil reprend les commandes d'Edition (Alt+E).

<h2>Menus de Word</h2>

```bat
WORD /?
WORD /CLASSICMENU
WORD /RUBANMENU "C:\Documents\Mon texte.docx"
```

Le mode classique est utilise par defaut. Les options sont insensibles a la
casse ; le dernier mode specifie est utilise. Le document peut etre place avant
ou apres les options. /? (ou -h, --help) affiche l'aide en console et quitte
sans ouvrir de fenetre ni charger de document.

Le ruban propose les commandes existantes dans des onglets avec icones
vectorielles, sans cadres permanents autour des boutons. Les commandes encore
non implementees sont grisees. Les deux barres d'outils classiques sont masquees ;
leurs commandes sont integrees aux onglets (mise en forme dans Accueil). La regle
et la zone de texte s'adaptent a l'espace libere.
Navigation : souris, F10 ou Alt+lettre, fleches, Tab/Maj+Tab, Entree et Echap.
L'onglet Accueil reprend les commandes d'Edition (Alt+E).

<h2>Menus d'Access</h2>

```bat
ACCESS /?
ACCESS /CLASSICMENU
ACCESS /RUBANMENU "C:\Documents\Ma base.mdb"
```

Le menu classique est utilise par defaut. Les options sont insensibles a la
casse ; le dernier mode specifie est utilise. Le fichier .MDB ou .SQL peut
apparaitre avant ou apres les options. /? (ou -h, --help) affiche l'aide en
console et quitte avant l'initialisation graphique et l'ecran de demarrage.

En mode ruban, la barre d'outils est masquee et toutes ses commandes figurent
dans les onglets, avec icones vectorielles et sans cadres permanents autour des
boutons. Les commandes non implementees sont grisees. La zone de travail
s'adapte a la hauteur du ruban. La cle primaire et les commandes de champs sont
disponibles dans Format. Navigation : souris, F10 ou Alt+lettre, fleches,
Tab/Maj+Tab, Entree et Echap. Les raccourcis des onglets sont listes dans l'aide.

<h2>Menus de OneNote</h2>

```bat
ONENOTE /?
ONENOTE /CLASSICMENU
ONENOTE /RUBANMENU
ONENOTE /RUBANMENU "C:\Notes\Mes notes.one"
```

Le mode classique est utilise par defaut. Les options sont insensibles a la
casse ; le dernier mode specifie est utilise. Le parametre de fichier existant
(.ONE ou .ONEPKG) peut apparaitre avant ou apres les options. /? (ou -h, --help)
affiche l'aide en console et quitte sans ouvrir de fenetre.

En mode ruban, la barre d'outils est masquee et ses commandes sont integrees
aux onglets avec icones vectorielles, sans cadres permanents. Accueil reprend
l'edition et la mise en forme courante. Les commandes non implementees sont
grisees. Les sections, pages et zones de saisie s'adaptent a la hauteur du ruban.
Navigation : souris, F10 ou Alt+lettre, fleches, Tab/Maj+Tab, Entree et Echap.
Les libelles suivent la langue FR/EN choisie dans Outils.

<h2>Menus de PowerPoint</h2>

```bat
POWERPNT /?
POWERPNT /CLASSICMENU
POWERPNT /RUBANMENU "C:\Documents\Ma presentation.pptx"
```

Le menu classique est utilise par defaut. Les options sont insensibles a la
casse ; le dernier mode specifie est utilise. Le fichier .PPT ou .PPTX peut
apparaitre avant ou apres les options. /? (ou -h, --help) affiche l'aide en
console et quitte avant l'initialisation graphique et l'ecran de demarrage.

En mode ruban, la barre d'outils est masquee et ses commandes sont integrees
aux onglets avec icones vectorielles et sans cadres permanents. Accueil regroupe
l'edition, la selection et la mise en forme. Insertion regroupe les outils de
dessin. Les commandes non implementees sont grisees. Les vues, miniatures,
regles et diapositives s'adaptent a la hauteur du ruban.

Navigation : souris, F10 ou Alt+lettre, fleches, Tab/Maj+Tab, Entree et Echap.
Les dix titres d'onglets sont abreges pour tenir dans les 640 pixels de largeur ;
leurs raccourcis sont listes dans l'aide de la commande.

<h2>Menus de Project</h2>

```bat
PROJECT /?
PROJECT /CLASSICMENU
PROJECT /RUBANMENU "C:\Documents\Mon projet.mpx"
```

Le menu classique est utilise par defaut. Les options sont insensibles a la
casse ; le dernier mode specifie est utilise. Un fichier .MPX, .XML, .CSV,
.MPP, .MPT, .MPD ou .PPM peut etre indique avant ou apres les options.
/? (ou -h, --help) affiche l'aide en console et quitte sans ouvrir de fenetre.

En mode ruban, la barre d'outils est masquee et toutes ses commandes figurent
dans les onglets avec icones vectorielles et sans cadres permanents. Les
commandes non implementees sont grisees. Les vues de travail s'adaptent a la
hauteur du ruban. Le survol et le focus clavier du ruban ne redessinent pas
la grille. Une saisie de cellule est validee avant l'ouverture d'un onglet.

Navigation : souris, F10 ou Alt+lettre, fleches, Tab/Maj+Tab, Entree et Echap.
Les raccourcis des neuf onglets sont listes dans l'aide de la commande.

<h2>VISIO : menus classiques et ruban</h2>

<ul>
<li><code>VISIO /CLASSICMENU [fichier.VSDX]</code> : menus classiques et barres d'outils (mode par defaut).</li>
<li><code>VISIO /RUBANMENU [fichier.VSDX]</code> : onglets avec icones et commandes, avec la barre d'outils verticale ; la barre horizontale est integree au ruban.</li>
<li>Les neuf outils de dessin restent accessibles dans la barre verticale dans les deux modes ; Nouveau, Ouvrir, Enregistrer,
Imprimer, Annuler et Retablir figurent dans Fichier et Edition.</li>
<li><code>VISIO /?</code> : aide en ligne de commande ; <code>-h</code> et <code>--help</code> sont aussi acceptes.</li>
<li>Les parametres sont insensibles a la casse ; le dernier mode indique est utilise.
Les chemins contenant des espaces peuvent etre places entre guillemets.</li>
<li>Navigation du ruban : souris, F10 ou raccourcis Alt des menus, fleches, Tab, Entree et Echap.
Les commandes sans gestionnaire existant restent grisees.</li>
</ul>

<h2>Licence</h2>
<ul>
 <li>Le code source est publié sous la licence <a href="https://github.com/gladir/OFFICE-0/blob/main/LICENSE">MIT</a>.</li>
 <li>Le paquet original est publié sous la licence <a href="https://github.com/gladir/OFFICE-0/blob/main/LICENSE">MIT</a>.</li>
</ul>
