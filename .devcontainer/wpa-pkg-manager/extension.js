// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
const { fstat } = require('fs');
const vscode = require('vscode');

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed

/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {
    // Use the console to output diagnostic information (console.log) and errors (console.error)
    // This line of code will only be executed once when your extension is activated
    console.log('Congratulations, your extension "wpa-pkg-manager" is now active!');

    // The command has been defined in the package.json file
    // Now provide the implementation of the command with  registerCommand
    // The commandId parameter must match the command field in package.json
    let disposable = vscode.commands.registerCommand('wpa-pkg-manager.helloWorld', function () {
        // The code you place here will be executed every time your command is executed

        // Display a message box to the user
        vscode.window.showInformationMessage('Hello World from WinGet Automation Packages Manager!');
    });

    let managePkgs = vscode.commands.registerCommand('wpa-pkg-manager.managePackages', async function () {
        let pkgList = new Map();
        let dirContents = await vscode.workspace.findFiles(`winget-pkgs-automation/packages/**/*.json`)
        if (dirContents.length === 0) {
            vscode.window.showInformationMessage('No packages found. Please verify you have opened vedantmgoyal2009 folder in your workspace.');
            return;
        }
        dirContents.forEach(file => {
            let packageIdentifier = file.path.substring(file.path.lastIndexOf('/') + 1, file.path.lastIndexOf('.'));
            pkgList.set(packageIdentifier, file.fsPath);
        });
        vscode.window.showQuickPick(Array.from(pkgList.keys()).sort(), {
            title: 'Select a package',
            placeHolder: 'Select a package from the list',
            canPickMany: false
        }).then(selection => {
            let selectedPkg = selection;
            let selectedPkgPath = pkgList.get(selectedPkg);
            vscode.window.showQuickPick([
                'open package json file',
                'skip package (prevent future updates)',
                'test package (using Test-Package.ps1)'
            ], {
                title: 'Select an action',
                placeHolder: 'Select an action from the list',
                canPickMany: false
            }).then(selection => {
                let selectedAction = selection;
                if (selectedAction.includes('open')) {
                    vscode.window.showTextDocument(selectedPkgPath);
                } else if (selectedAction.includes('skip')) {
                    vscode.workspace.fs.readFile(vscode.Uri.file(`${vscode.workspace.workspaceFolders[0].uri.path}/winget-pkgs-automation/schema.json`)).then(schemaDoc => {
                        let skipChoices = JSON.parse(Buffer.from(schemaDoc).toString('utf8')).properties.SkipPackage.enum;
                        skipChoices[skipChoices.indexOf(false)] = 'false';
                        vscode.window.showQuickPick(skipChoices, {
                            title: 'Select a reason to skip package',
                            placeHolder: 'Select a reason to skip package from the list',
                            canPickMany: false
                        }).then(selection => {
                            let skipReason = selection === 'false' ? false : selection;
                            vscode.workspace.openTextDocument(selectedPkgPath).then(pkgDoc => {
                                let pkgObj = JSON.parse(pkgDoc.getText());
                                pkgObj.SkipPackage = skipReason;
                                vscode.workspace.fs.writeFile(pkgDoc.uri, Buffer.from(JSON.stringify(pkgObj, null, 2))).then(() => {
                                    vscode.window.showInformationMessage(`Skip ${selectedPkg} reason: ${skipReason}`);
                                });
                            });
                        });
                    });
                } else if (selectedAction.includes('test')) {
                    vscode.window.createTerminal({
                        name: `Test ${selectedPkg}`,
                        cwd: `${vscode.workspace.workspaceFolders[0].uri.fsPath}/winget-pkgs-automation/tools`,
                        shellPath: 'pwsh.exe',
                        shellArgs: ['-NoProfile',
                            '-NoExit',
                            '-Command',
                            './Test-Package.ps1',
                            '-PackageIdentifier',
                            `${selectedPkg}`,
                            '-DisableRecursion',
                            '| Format-List -Property *'
                        ],
                        hideFromUser: false
                    }).show();
                }
            });
        });
    });

    context.subscriptions.push(disposable);
    context.subscriptions.push(managePkgs);
}

// this method is called when your extension is deactivated
function deactivate() { }

module.exports = {
    activate,
    deactivate
}
