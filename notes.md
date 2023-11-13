# Dark Mode for Help Files

From the [scsynth.org forum](https://scsynth.org/t/which-ide-do-you-use/687/21). Add the following
text to the bottom of `scdoc.css`. On OS X this lives in `~/Library/Application
Support/SuperCollider/Help/scdoc.css`

```
body {
    -webkit-filter: invert(100%);
    filter: invert(100%);
    background: #333;
    color: #555;
}
```
