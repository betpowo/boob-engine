var doc = fl.getDocumentDOM();
var selection = doc.selection;

for (var i = 0; i < selection.length; i++) {
	selection[i].libraryItem.name = '! ' + selection[i].libraryItem.name;
	fl.outputPanel.trace(selection[i].libraryItem.name);
}