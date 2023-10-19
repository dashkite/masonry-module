import Path from "node:path"
import * as Fn from "@dashkite/joy/function"
import Zephyr from "@dashkite/zephyr"
import { log, getCollection, Template, hash } from "./helpers"

$hashes = Path.join ".sky", "hashes.yaml"

Module =

  data: Fn.tee ( context ) ->
    data = await Zephyr.read "package.json"
    context.module = data

  publish: ( template ) ->
    Fn.tee ( context ) ->
      collection = await getCollection()
      key = Template.expand template, context
      log "publishing #{ context.source.path }"
      collection.put key, context.input

  rm: ( template ) ->
    Fn.tee ( context ) ->
      collection = await getCollection()
      key = Template.expand template, context
      log "delete #{ context.source.path }"
      collection.delete key

File =

  hash: Fn.tee ({ source, input }) ->
    if input?
      source.hash = hash input
    else
      hashes = await Zephyr.read $hashes
      source.hash = hashes[ source.path ]

  stamp: Fn.tee ({ source }) ->
    Zephyr.update $hashes, ( hashes ) ->
      hashes ?= {}
      hashes[ source.path ] = source.hash
      hashes
  
  evict: Fn.tee ({ source }) ->
    Zephyr.update $hashes, ( hashes ) ->
      hashes ?= {}
      delete hashes[ source.path ]
      hashes

  changed: ( action ) ->
    Fn.tee ( context ) ->
      hashes = await Zephyr.read $hashes
      if hashes?[ context.source.path ] != context.source.hash
        # explicit await since we return the context
        await action context

export { Module, File }