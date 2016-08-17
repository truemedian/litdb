return {
  name = 'voronianski/oauth',
  version = '1.0.1',
  description = 'OAuth wrapper for Luvit.io',
  repository = {
    url = 'https://github.com/luvitrocks/luvit-oauth.git',
  },
  tags = {'utopia', 'server', 'oauth', 'oauth2', 'request', 'auth', 'wrapper'},
  author = {
    name = 'Dmitri Voronianski',
    email = 'dmitri.voronianski@gmail.com'
  },
  homepage = 'https://github.com/luvitrocks/luvit-oauth',
  dependencies = {
    'filwisher/lua-tape'
  },
  licenses = {'MIT'},
  files = {
    '**.lua',
    '!test*',
    '!example*'
  }
}
