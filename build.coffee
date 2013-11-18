stitch  = require('stitch')
fs      = require('fs')

pack = stitch.createPackage({
    paths: [__dirname + '/src', __dirname + '/static']
})

pack.compile((err, source) ->
    fs.writeFile('build/package.js', source, (err) ->
        throw err if (err)
        console.log('Compiled package.js')
    )
)
