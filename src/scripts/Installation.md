# Adding the scripts to PATH
To be able to execute the scripts from anywhere add the following lines to your `bashrc`/ `zhshrc` file:

```sh
if [[ ":$PATH:" != *":<path-to-project>/roehr/src/scripts:"* ]]; then
    export PATH="<path-to-project>/roehr/src/scripts:$PATH"
fi

if [[ ":$PYTHONPATH:" != *":<path-to-project>/roehr/src/scripts:"* ]]; then
    export PYTHONPATH="<path-to-project>/roehr/src/scripts:$PYTHONPATH"
fi
```

# Test Circom Files
To run a test case `testCase.sage` for some template `someTemplate` in a file `file.circom` follow these steps:
1. Remove the comments from the commented out lines of code underneath `# test` in `someTemplate`.
2. Remove the comments from the line with `component main = someTemplate(...)`.
3. Navigate to the folder in which the file is located and run:
```
genCircom.sh file.circom test/testCases/testCase.sage
```