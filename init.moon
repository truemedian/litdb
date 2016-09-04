----
 -- node-exceptions
 --
 -- (c) 'Damilare Darmie Akinlaja <darmie@riot.ng>
 --
 -- For the full copyright and license information, please view the LICENSE
 -- file that was distributed with this source code.
--

LogicalException = require('./src/LogicalException')


exports.LogicalException = LogicalException
exports.DomainException = class DomainException extends LogicalException
exports.InvalidArgumentException = class InvalidArgumentException extends LogicalException
exports.RangeException = class RangeException extends LogicalException
exports.RuntimeException = class RuntimeException extends LogicalException
exports.HttpException = class HttpException extends LogicalException
