# OFFICE-0
Liste de commandes écrit en Pascal (Turbo Pascal et/ou Free Pascal) pour le bureau

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
      <td><b>ACCESS.PAS</b></td>
      <td>Cette commande permet de lancer un clone de Access.</td>
    </tr>
	<tr>
		<td><b>EXCEL.PAS</b></td>
		<td>Cette commande permet de lancer un clone de Excel.</td>
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

<h2>Licence</h2>
<ul>
 <li>Le code source est publié sous la licence <a href="https://github.com/gladir/OFFICE-0/blob/main/LICENSE">MIT</a>.</li>
 <li>Le paquet original est publié sous la licence <a href="https://github.com/gladir/OFFICE-0/blob/main/LICENSE">MIT</a>.</li>
</ul>
