import Path from "node:path"
import Crypto from "node:crypto"
import Zephyr from "@dashkite/zephyr"
import * as DRN from "@dashkite/drn-sky"
import * as Time from "@dashkite/joy/time"
import * as Graphene from "@dashkite/graphene-core"
import * as TK from "terminal-kit"
import configuration from "./configuration"

log = ( text ) ->
  TK.terminal.blue "genie-modules: #{ text }\n"

getClient = ->
  tables = {}
  for key, value of configuration.dynamodb.tables
    tables[ key ] = await DRN.resolve value
  Graphene.Client.create { tables }


# TODO might be nice to build this pattern into the client
getCollection = do ({ collection } = {}) -> ->
  client = await getClient()
  db = client.db await DRN.resolve configuration.graphene.db
  domain = await DRN.resolve configuration.domain
  if !( collection = await db.collection.get domain )?
    log "Creating module collection. We only need to do this once."
    collection = await db.collection.create byname: domain
    loop
      response = await db.collection.getStatus domain
      break if response.status == "ready"
      await Time.sleep 5000
    log "Collection ready. Continuing..."
  collection.entries

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

export { log, getCollection, Template, hash }