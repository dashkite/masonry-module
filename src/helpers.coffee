import Crypto from "node:crypto"
import * as TK from "terminal-kit"

log = ( text ) ->
  TK.terminal.green "masonry-module: #{ text }\n"

Template =

  # TODO migrate into Joy
  expand: ( template, context ) ->
    parameters = Object.keys context
    f = new Function "{#{ parameters }}", "return `#{ template }`"
    f context

hash = ( value ) ->
  hashed = Crypto
    .createHash "sha256"
    .update JSON.stringify value
    .digest "base64url"
  hashed[...8]

export { log, Template, hash }