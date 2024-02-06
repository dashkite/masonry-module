import Path from "node:path"
import * as Fn from "@dashkite/joy/function"
import Zephyr from "@dashkite/zephyr"
import { log, Template, hash } from "./helpers"
import * as X3 from "@dashkite/dolores/s3-combinators"
import * as S3 from "@dashkite/dolores/s3"

$hashes = Path.join ".sky", "hashes.yaml"


Module =

  data: Fn.tee ( context ) ->
    data = await Zephyr.read "package.json"
    context.module = data

File =

  publish: ({ template, bucket, cache }) ->
    Fn.tee ( context ) ->
      log "publishing #{ context.source.path }"
      key = if template?
        Template.expand template, context
      else context.source.path
      do Fn.pipe [
        X3.bucket bucket
        X3.key key
        X3.body context.input
        X3.cache cache
        X3.put
      ]

  rm: ({ template, bucket }) ->
    Fn.tee ( context ) ->
      collection = await getCollection()
      key = if template?
        Template.expand template, context
      else context.source.path
      log "delete #{ context.source.path }"
      S3.deleteObject bucket, key

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