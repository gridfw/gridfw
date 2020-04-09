console.log '-- check URL'

Url= require 'querystringparser'

parsed= Url.parse('user[name][first]=tj&user[name][last]=holowaychuk', true);
console.log '>>', parsed

console.log "============================"
parsed= Url.parse('a=1&b=2&a=3&a=hello', true);
console.log '>>', parsed