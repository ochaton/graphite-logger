package = "graphite"
version = "scm-1"
source = {
   url = "https://github.com/orchaton/graphite-logger"
}
description = {
   homepage = "https://github.com/orchaton/graphite-logger",
   license = "BSD"
}
dependencies = {
   "lua ~> 5.1",
}
build = {
   type = "builtin",
   modules = {
      graphite = "graphite.lua"
   }
}
