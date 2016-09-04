----
 -- node-exceptions
 --
 -- (c) 'Damilare Darmie Akinlaja <darmie@riot.ng>
 --
 -- For the full copyright and license information, please view the LICENSE
 -- file that was distributed with this source code.
--

class LogicalException extends debug
  new: (message, status, code) =>
    debug.traceback!
    @name = @__name
    @message = if code then "#{code}: #{message}" else message
    @status = status or 500
    @code = code

exports.LogicalException = LogicalException
