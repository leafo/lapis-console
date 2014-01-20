return [==[
body {
  font-family: sans-serif;
  font-size: 16px;
  background: #D6D6D6;
  margin: 0; }

#editor .CodeMirror {
  height: auto; }
#editor .CodeMirror-scroll {
  overflow-y: hidden;
  overflow-x: auto; }
#editor .editor_top {
  background: whitesmoke;
  padding: 20px;
  border-bottom: 1px solid #B1AFAF;
  box-shadow: 0 -2px 4px 4px rgba(0, 0, 0, 0.15); }
#editor .log {
  padding: 0 20px; }
#editor .footer {
  text-align: center;
  margin: 10px;
  font-size: 12px;
  color: #838383; }
#editor .buttons_top {
  font-size: 0;
  margin-bottom: 7px; }
  #editor .buttons_top button {
    font-size: 16px;
    background: #8AA8CF;
    color: #294464;
    border: 0;
    margin: 0 10px 0 0;
    padding: 5px 10px;
    border-radius: 4px;
    -webkit-transition: background 0.2s ease-in-out;
    -moz-transition: background 0.2s ease-in-out;
    transition: background 0.2s ease-in-out; }
    #editor .buttons_top button:hover {
      background: #9cb6d6; }
    #editor .buttons_top button:active {
      position: relative;
      top: 1px; }
#editor .status {
  background: #7BB87B;
  text-shadow: 1px 1px 1px #488548;
  color: white;
  padding: 4px 8px;
  -webkit-transition: background 0.2s ease-in-out;
  -moz-transition: background 0.2s ease-in-out;
  transition: background 0.2s ease-in-out; }
  #editor .status.error {
    background: #C25353;
    text-shadow: 1px 1px 1px #a73b3b; }
  #editor .status.loading {
    background: #E9D674;
    text-shadow: 1px 1px 1px #a9911b; }
#editor .has_error {
  background: rgba(255, 0, 0, 0.2); }
#editor .result {
  border: 1px solid silver;
  background: white;
  box-shadow: 1px 1px 4px rgba(0, 0, 0, 0.15);
  color: #444;
  margin: 10px 0; }
  #editor .result.no_output {
    font-style: italic;
    color: #888;
    padding: 10px; }
  #editor .result .line {
    font-family: monospace; }
  #editor .result .value {
    margin: 5px;
    padding: 5px;
    display: inline-block;
    vertical-align: top; }
    #editor .result .value.string {
      color: #648164; }
      #editor .result .value.string:before {
        font-weight: bold;
        content: '"'; }
      #editor .result .value.string:after {
        font-weight: bold;
        content: '"'; }
      #editor .result .value.string.key:before {
        content: ""; }
    #editor .result .value.boolean {
      color: #664B66; }
    #editor .result .value.number {
      color: #5076A0; }
    #editor .result .value.function, #editor .result .value.recursion, #editor .result .value.metatable {
      color: #888;
      font-style: italic; }
    #editor .result .value .recursion:before {
      content: "(recursion) ";
      font-style: normal;
      font-weight: bold;
      font-size: 14px; }
    #editor .result .value.key {
      margin-right: 0;
      padding-right: 0; }
      #editor .result .value.key:after {
        content: ": ";
        font-style: normal;
        font-weight: bold;
        color: #444; }
    #editor .result .value:hover {
      background: #eee;
      border-radius: 3px; }
    #editor .result .value.expanded {
      border-left: 1px dashed silver;
      margin-left: 10px;
      padding: 0; }
      #editor .result .value.expanded:hover {
        background: white; }
  #editor .result .sep {
    padding: 5px 0;
    font-weight: bold;
    display: inline-block; }
  #editor .result .tuple {
    margin-left: 10px; }
    #editor .result .tuple > .value {
      margin-top: 0;
      margin-bottom: 0; }
  #editor .result .expandable {
    cursor: pointer;
    font-weight: bold; }
  #editor .result .closable {
    font-weight: bold;
    vertical-align: top;
    display: inline-block;
    cursor: pointer;
    padding: 5px;
    margin: 5px; }
    #editor .result .closable:first-child {
      margin-bottom: 0; }
    #editor .result .closable:last-child {
      margin-top: 0; }
    #editor .result .closable:hover {
      background: #eee;
      border-radius: 3px; }
  #editor .result .queries {
    font-family: monospace;
    background: #ddd;
    border: 1px solid white; }
    #editor .result .queries:before {
      content: "Queries:";
      display: block;
      background: #c4c4c4;
      border-bottom: 1px solid #B4B4B4;
      text-shadow: 1px 1px 0 #ddd;
      font-size: 12px;
      padding: 5px;
      font-family: sans-serif; }
    #editor .result .queries .query {
      padding: 5px; }
]==]
