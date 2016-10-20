function fileType (buffer)
  local buf = {}
  local bufLength = buffer and buffer.length

  if not bufLength or bufLength < 1 then
    return nil
  end

  for i = 1, tonumber(bufLength) do
    buf[i] = string.upper(bit.tohex(buffer[i], 2))
  end

  if buf[1] == 'FF' and buf[2] == 'D8' and buf[3] == 'FF' then
    return {
      ext = 'jpg',
      mime = 'image/jpeg'
    }
  end

  if buf[1] == '89' and buf[2] == '50' and buf[3] == '4E' and buf[4] == '47' then
    return {
      ext = 'png',
      mime = 'image/png'
    }
  end

  if buf[1] == '47' and buf[2] == '49' and buf[3] == '46' then
    return {
      ext = 'gif',
      mime = 'image/gif'
    }
  end

  if buf[1] == '46' and buf[2] == '4C' and buf[3] == '49' and buf[4] == '46' then
    return {
      ext = 'flif',
      mime = 'image/flif'
    }
  end

  -- needs to be before `tif` check
  if ((buf[1] == '49' and buf[2] == '49' and buf[3] == '2A' and buf[4] == '0') or (buf[1] == '4D' and buf[2] == '4D' and buf[3] == '0' and buf[4] == '2A')) and buf[7] == '43' and buf[8] == '52' then
    return {
      ext = 'cr2',
      mime = 'image/x-canon-cr2'
    }
  end

  if (buf[1] == '49' and buf[2] == '49' and buf[3] == '2A' and buf[4] == '0') or (buf[1] == '4D' and buf[2] == '4D' and buf[3] == '0' and buf[4] == '2A') then
    return {
      ext = 'tif',
      mime = 'image/tiff'
    }
  end

  if buf[1] == '42' and buf[2] == '4D' then
    return {
      ext = 'bmp',
      mime = 'image/bmp'
    }
  end

  if buf[1] == '49' and buf[2] == '49' and buf[3] == 'BC' then
    return {
      ext = 'jxr',
      mime = 'image/vnd.ms-photo'
    }
  end

  if buf[1] == '38' and buf[2] == '42' and buf[3] == '50' and buf[4] == '53' then
    return {
      ext = 'psd',
      mime = 'image/vnd.adobe.photoshop'
    }
  end

  -- needs to be before `zip` check
  if buf[1] == '50' and buf[2] == '4B' and buf[3] == '3' and buf[4] == '4' and buf[31] == '6D' and buf[32] == '69' and buf[33] == '6D' and buf[34] == '65' and buf[35] == '74' and buf[36] == '79' and buf[37] == '70' and buf[38] == '65' and buf[39] == '61' and buf[40] == '70' and buf[41] == '70' and buf[42] == '6C' and buf[43] == '69' and buf[44] == '63' and buf[45] == '61' and buf[46] == '74' and buf[47] == '69' and buf[48] == '6F' and buf[49] == '6E' and buf[50] == '2F' and buf[51] == '65' and buf[52] == '70' and buf[53] == '75' and buf[54] == '62' and buf[55] == '2B' and buf[56] == '7A' and buf[57] == '69' and buf[58] == '70' then
    return {
      ext = 'epub',
      mime = 'application/epub+zip'
    }
  end

  -- needs to be before `zip` check
  -- assumes signed .xpi from addons.mozilla.org
  if buf[1] == '50' and buf[2] == '4B' and buf[3] == '3' and buf[4] == '4' and buf[31] == '4D' and buf[32] == '45' and buf[33] == '54' and buf[34] == '41' and buf[35] == '2D' and buf[36] == '49' and buf[37] == '4E' and buf[38] == '46' and buf[39] == '2F' and buf[40] == '6D' and buf[41] == '6F' and buf[42] == '7A' and buf[43] == '69' and buf[44] == '6C' and buf[45] == '6C' and buf[46] == '61' and buf[47] == '2E' and buf[48] == '72' and buf[49] == '73' and buf[50] == '61' then
    return {
      ext = 'xpi',
      mime = 'application/x-xpinstall'
    }
  end

  if buf[1] == '50' and buf[2] == '4B' and (buf[3] == '3' or buf[3] == '5' or buf[3] == '7') and (buf[4] == '4' or buf[4] == '6' or buf[4] == '8') then
    return {
      ext = 'zip',
      mime = 'application/zip'
    }
  end

  if buf[258] == '75' and buf[259] == '73' and buf[260] == '74' and buf[261] == '61' and buf[262] == '72' then
    return {
      ext = 'tar',
      mime = 'application/x-tar'
    }
  end

  if buf[1] == '52' and buf[2] == '61' and buf[3] == '72' and buf[4] == '21' and buf[5] == '1A' and buf[6] == '7' and (buf[7] == '0' or buf[7] == '1') then
    return {
      ext = 'rar',
      mime = 'application/x-rar-compressed'
    }
  end

  if buf[1] == '1F' and buf[2] == '8B' and buf[3] == '8' then
    return {
      ext = 'gz',
      mime = 'application/gzip'
    }
  end

  if buf[1] == '42' and buf[2] == '5A' and buf[3] == '68' then
    return {
      ext = 'bz2',
      mime = 'application/x-bzip2'
    }
  end

  if buf[1] == '37' and buf[2] == '7A' and buf[3] == 'BC' and buf[4] == 'AF' and buf[5] == '27' and buf[6] == '1C' then
    return {
      ext = '7z',
      mime = 'application/x-7z-compressed'
    }
  end

  if buf[1] == '78' and buf[2] == '01' then
    return {
      ext = 'dmg',
      mime = 'application/x-apple-diskimage'
    }
  end

  if (buf[1] == '0' and buf[2] == '0' and buf[3] == '0' and (buf[4] == '18' or buf[4] == '20') and buf[5] == '66' and buf[6] == '74' and buf[7] == '79' and buf[8] == '70') or (buf[1] == '33' and buf[2] == '67' and buf[3] == '70' and buf[4] == '35') or (buf[1] == '0' and buf[2] == '0' and buf[3] == '0' and buf[4] == '1C' and buf[5] == '66' and buf[6] == '74' and buf[7] == '79' and buf[8] == '70' and buf[9] == '6D' and buf[10] == '70' and buf[11] == '34' and buf[12] == '32' and buf[17] == '6D' and buf[18] == '70' and buf[19] == '34' and buf[20] == '31' and buf[21] == '6D' and buf[22] == '70' and buf[23] == '34' and buf[24] == '32' and buf[25] == '69' and buf[26] == '73' and buf[27] == '6F' and buf[28] == '6D') or (buf[1] == '0' and buf[2] == '0' and buf[3] == '0' and buf[4] == '1C' and buf[5] == '66' and buf[6] == '74' and buf[7] == '79' and buf[8] == '70' and buf[9] == '69' and buf[10] == '73' and buf[11] == '6F' and buf[12] == '6D') or (buf[1] == '0' and buf[2] == '0' and buf[3] == '0' and buf[4] == '1c' and buf[5] == '66' and buf[6] == '74' and buf[7] == '79' and buf[8] == '70' and buf[9] == '6D' and buf[10] == '70' and buf[11] == '34' and buf[12] == '32' and buf[13] == '0' and buf[14] == '0' and buf[15] == '0' and buf[16] == '0') then
    return {
      ext = 'mp4',
      mime = 'video/mp4'
    }
  end

  if (buf[1] == '0' and buf[2] == '0' and buf[3] == '0' and buf[4] == '1C' and buf[5] == '66' and buf[6] == '74' and buf[7] == '79' and buf[8] == '70' and buf[9] == '4D' and buf[10] == '34' and buf[11] == '56') then
    return {
      ext = 'm4v',
      mime = 'video/x-m4v'
    }
  end

  if buf[1] == '4D' and buf[2] == '54' and buf[3] == '68' and buf[4] == '64' then
    return {
      ext = 'mid',
      mime = 'audio/midi'
    }
  end

  -- needs to be before the `webm` check
  if buf[32] == '6D' and buf[33] == '61' and buf[34] == '74' and buf[35] == '72' and buf[36] == '6f' and buf[37] == '73' and buf[38] == '6B' and buf[39] == '61' then
    return {
      ext = 'mkv',
      mime = 'video/x-matroska'
    }
  end

  if buf[1] == '1A' and buf[2] == '45' and buf[3] == 'DF' and buf[4] == 'A3' then
    return {
      ext = 'webm',
      mime = 'video/webm'
    }
  end

  if buf[1] == '0' and buf[2] == '0' and buf[3] == '0' and buf[4] == '14' and buf[5] == '66' and buf[6] == '74' and buf[7] == '79' and buf[8] == '70' then
    return {
      ext = 'mov',
      mime = 'video/quicktime'
    }
  end

  if buf[1] == '52' and buf[2] == '49' and buf[3] == '46' and buf[4] == '46' and buf[9] == '41' and buf[10] == '56' and buf[11] == '49' then
    return {
      ext = 'avi',
      mime = 'video/x-msvideo'
    }
  end

  if buf[1] == '30' and buf[2] == '26' and buf[3] == 'B2' and buf[4] == '75' and buf[5] == '8E' and buf[6] == '66' and buf[7] == 'CF' and buf[8] == '11' and buf[9] == 'A6' and buf[10] == 'D9' then
    return {
      ext = 'wmv',
      mime = 'video/x-ms-wmv'
    }
  end

  if buf[1] == '0' and buf[2] == '0' and buf[3] == '1' and buf[4].toString(16)[1] == 'b' then
    return {
      ext = 'mpg',
      mime = 'video/mpeg'
    }
  end

  if (buf[1] == '49' and buf[2] == '44' and buf[3] == '33') or (buf[1] == 'FF' and buf[2] == 'fb') then
    return {
      ext = 'mp3',
      mime = 'audio/mpeg'
    }
  end

  if (buf[5] == '66' and buf[6] == '74' and buf[7] == '79' and buf[8] == '70' and buf[9] == '4D' and buf[10] == '34' and buf[11] == '41') or (buf[1] == '4D' and buf[2] == '34' and buf[3] == '41' and buf[4] == '20') then
    return {
      ext = 'm4a',
      mime = 'audio/m4a'
    }
  end

  -- needs to be before `ogg` check
  if buf[29] == '4F' and buf[30] == '70' and buf[31] == '75' and buf[32] == '73' and buf[33] == '48' and buf[34] == '65' and buf[35] == '61' and buf[36] == '64' then
    return {
      ext = 'opus',
      mime = 'audio/opus'
    }
  end

  if buf[1] == '4F' and buf[2] == '67' and buf[3] == '67' and buf[4] == '53' then
    return {
      ext = 'ogg',
      mime = 'audio/ogg'
    }
  end

  if buf[1] == '66' and buf[2] == '4C' and buf[3] == '61' and buf[4] == '43' then
    return {
      ext = 'flac',
      mime = 'audio/x-flac'
    }
  end

  if buf[1] == '52' and buf[2] == '49' and buf[3] == '46' and buf[4] == '46' and buf[9] == '57' and buf[10] == '41' and buf[11] == '56' and buf[12] == '45' then
    return {
      ext = 'wav',
      mime = 'audio/x-wav'
    }
  end

  if buf[1] == '23' and buf[2] == '21' and buf[3] == '41' and buf[4] == '4D' and buf[5] == '52' and buf[6] == '0A' then
    return {
      ext = 'amr',
      mime = 'audio/amr'
    }
  end

  if buf[1] == '25' and buf[2] == '50' and buf[3] == '44' and buf[4] == '46' then
    return {
      ext = 'pdf',
      mime = 'application/pdf'
    }
  end

  if buf[1] == '4D' and buf[2] == '5A' then
    return {
      ext = 'exe',
      mime = 'application/x-msdownload'
    }
  end

  if (buf[1] == '43' or buf[1] == '46') and buf[2] == '57' and buf[3] == '53' then
    return {
      ext = 'swf',
      mime = 'application/x-shockwave-flash'
    }
  end

  if buf[1] == '7B' and buf[2] == '5C' and buf[3] == '72' and buf[4] == '74' and buf[5] == '66' then
    return {
      ext = 'rtf',
      mime = 'application/rtf'
    }
  end

  if (buf[1] == '77' and buf[2] == '4F' and buf[3] == '46' and buf[4] == '46') and ((buf[5] == '00' and buf[6] == '01' and buf[7] == '00' and buf[8] == '00') or (buf[5] == '4F' and buf[6] == '54' and buf[7] == '54' and buf[8] == '4F')) then
    return {
      ext = 'woff',
      mime = 'application/font-woff'
    }
  end

  if (buf[1] == '77' and buf[2] == '4F' and buf[3] == '46' and buf[4] == '32') and ((buf[5] == '00' and buf[6] == '01' and buf[7] == '00' and buf[8] == '00') or (buf[5] == '4F' and buf[6] == '54' and buf[7] == '54' and buf[8] == '4F')) then
    return {
      ext = 'woff2',
      mime = 'application/font-woff'
    }
  end

  if buf[35] == '4C' and buf[36] == '50') and ((buf[9] == '00' and buf[10] == '00' and buf[11] == '01') or (buf[9] == '01' and buf[10] == '00' and buf[11] == '02') or (buf[9] == '02' and buf[10] == '00' and buf[11] == '02') then
    return {
      ext = 'eot',
      mime = 'application/octet-stream'
    }
  end

  if buf[1] == '00' and buf[2] == '01' and buf[3] == '00' and buf[4] == '00' and buf[5] == '00' then
    return {
      ext = 'ttf',
      mime = 'application/font-sfnt'
    }
  end

  if buf[1] == '4F' and buf[2] == '54' and buf[3] == '54' and buf[4] == '4F' and buf[5] == '00' then
    return {
      ext = 'otf',
      mime = 'application/font-sfnt'
    }
  end

  if buf[1] == '00' and buf[2] == '00' and buf[3] == '01' and buf[4] == '00' then
    return {
      ext = 'ico',
      mime = 'image/x-icon'
    }
  end

  if buf[1] == '46' and buf[2] == '4C' and buf[3] == '56' and buf[4] == '01' then
    return {
      ext = 'flv',
      mime = 'video/x-flv'
    }
  end

  if buf[1] == '25' and buf[2] == '21' then
    return {
      ext = 'ps',
      mime = 'application/postscript'
    }
  end

  if buf[1] == 'FD' and buf[2] == '37' and buf[3] == '7A' and buf[4] == '58' and buf[5] == '5A' and buf[6] == '00' then
    return {
      ext = 'xz',
      mime = 'application/x-xz'
    }
  end

  if buf[1] == '53' and buf[2] == '51' and buf[3] == '4C' and buf[4] == '69' then
    return {
      ext = 'sqlite',
      mime = 'application/x-sqlite3'
    }
  end

  if buf[1] == '4E' and buf[2] == '45' and buf[3] == '53' and buf[4] == '1A' then
    return {
      ext = 'nes',
      mime = 'application/x-nintendo-nes-rom'
    }
  end

  if buf[1] == '43' and buf[2] == '72' and buf[3] == '32' and buf[4] == '34' then
    return {
      ext = 'crx',
      mime = 'application/x-google-chrome-extension'
    }
  end

  if buf[1] == '4D' and buf[2] == '53' and buf[3] == '43' and buf[4] == '46') or (buf[1] == '49' and buf[2] == '53' and buf[3] == '63' and buf[4] == '28' then
    return {
      ext = 'cab',
      mime = 'application/vnd.ms-cab-compressed'
    }
  end

  -- needs to be before `ar` check
  if buf[1] == '21' and buf[2] == '3C' and buf[3] == '61' and buf[4] == '72' and buf[5] == '63' and buf[6] == '68' and buf[7] == '3E' and buf[8] == '0A' and buf[9] == '64' and buf[10] == '65' and buf[11] == '62' and buf[12] == '69' and buf[13] == '61' and buf[14] == '6E' and buf[15] == '2D' and buf[16] == '62' and buf[17] == '69' and buf[18] == '6E' and buf[19] == '61' and buf[20] == '72' and buf[21] == '79' then
    return {
      ext = 'deb',
      mime = 'application/x-deb'
    }
  end

  if buf[1] == '21' and buf[2] == '3C' and buf[3] == '61' and buf[4] == '72' and buf[5] == '63' and buf[6] == '68' and buf[7] == '3E' then
    return {
      ext = 'ar',
      mime = 'application/x-unix-archive'
    }
  end

  if buf[1] == 'ED' and buf[2] == 'AB' and buf[3] == 'EE' and buf[4] == 'DB' then
    return {
      ext = 'rpm',
      mime = 'application/x-rpm'
    }
  end

  if buf[1] == '1F' and buf[2] == 'A0') or (buf[1] == '1F' and buf[2] == '9D' then
    return {
      ext = 'Z',
      mime = 'application/x-compress'
    }
  end

  if buf[1] == '4C' and buf[2] == '5A' and buf[3] == '49' and buf[4] == '50' then
    return {
      ext = 'lz',
      mime = 'application/x-lzip'
    }
  end

  if buf[1] == 'D0' and buf[2] == 'CF' and buf[3] == '11' and buf[4] == 'E0' and buf[5] == 'A1' and buf[6] == 'B1' and buf[7] == '1A' and buf[8] == 'E1' then
    return {
      ext = 'msi',
      mime = 'application/x-msi'
    }
  end

  return nil
end

return fileType
