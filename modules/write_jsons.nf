process WRITE_JSONS {
        input:
        val versions

        output:
        path vjson, emit: vjson
        path pjson, emit: pjson

        exec:
        vjson = task.workDir.resolve('versions.json')
        pjson = task.workDir.resolve('params.json')
        jsonVersions = new groovy.json.JsonBuilder(versions).toPrettyString()
        file(vjson).text = jsonVersions
        jsonParams = new groovy.json.JsonBuilder(params).toPrettyString()
        file(pjson).text = jsonParams
}
