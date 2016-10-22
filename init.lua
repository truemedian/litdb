function fileType (buf)
  local bufLength = buf and buf.length

  if not bufLength or bufLength < 1 then
    return nil
  end

  if buf[1] == 0xFF and buf[2] == 0xD8 and buf[3] == 0xFF then
    return {
      ext = 'jpg',
      mime = 'image/jpeg'
    }
  end

  if buf[1] == 0x89 and buf[2] == 0x50 and buf[3] == 0x4E and buf[4] == 0x47 then
    return {
      ext = 'png',
      mime = 'image/png'
    }
  end

  if buf[1] == 0x47 and buf[2] == 0x49 and buf[3] == 0x46 then
    return {
      ext = 'gif',
      mime = 'image/gif'
    }
  end

  if buf[1] == 0x46 and buf[2] == 0x4C and buf[3] == 0x49 and buf[4] == 0x46 then
    return {
      ext = 'flif',
      mime = 'image/flif'
    }
  end

  -- needs to be before `tif` check
  if ((buf[1] == 0x49 and buf[2] == 0x49 and buf[3] == 0x2A and buf[4] == 0x0) or (buf[1] == 0x4D and buf[2] == 0x4D and buf[3] == 0x0 and buf[4] == 0x2A)) and buf[7] == 0x43 and buf[8] == 0x52 then
    return {
      ext = 'cr2',
      mime = 'image/x-canon-cr2'
    }
  end

  if (buf[1] == 0x49 and buf[2] == 0x49 and buf[3] == 0x2A and buf[4] == 0x0) or (buf[1] == 0x4D and buf[2] == 0x4D and buf[3] == 0x0 and buf[4] == 0x2A) then
    return {
      ext = 'tif',
      mime = 'image/tiff'
    }
  end

  if buf[1] == 0x42 and buf[2] == 0x4D then
    return {
      ext = 'bmp',
      mime = 'image/bmp'
    }
  end

  if buf[1] == 0x49 and buf[2] == 0x49 and buf[3] == 0xBC then
    return {
      ext = 'jxr',
      mime = 'image/vnd.ms-photo'
    }
  end

  if buf[1] == 0x38 and buf[2] == 0x42 and buf[3] == 0x50 and buf[4] == 0x53 then
    return {
      ext = 'psd',
      mime = 'image/vnd.adobe.photoshop'
    }
  end

  -- needs to be before `zip` check
  if buf[1] == 0x50 and buf[2] == 0x4B and buf[3] == 0x3 and buf[4] == 0x4 and buf[31] == 0x6D and buf[32] == 0x69 and buf[33] == 0x6D and buf[34] == 0x65 and buf[35] == 0x74 and buf[36] == 0x79 and buf[37] == 0x70 and buf[38] == 0x65 and buf[39] == 0x61 and buf[40] == 0x70 and buf[41] == 0x70 and buf[42] == 0x6C and buf[43] == 0x69 and buf[44] == 0x63 and buf[45] == 0x61 and buf[46] == 0x74 and buf[47] == 0x69 and buf[48] == 0x6F and buf[49] == 0x6E and buf[50] == 0x2F and buf[51] == 0x65 and buf[52] == 0x70 and buf[53] == 0x75 and buf[54] == 0x62 and buf[55] == 0x2B and buf[56] == 0x7A and buf[57] == 0x69 and buf[58] == 0x70 then
    return {
      ext = 'epub',
      mime = 'application/epub+zip'
    }
  end

  -- needs to be before `zip` check
  -- assumes signed .xpi from addons.mozilla.org
  if buf[1] == 0x50 and buf[2] == 0x4B and buf[3] == 0x3 and buf[4] == 0x4 and buf[31] == 0x4D and buf[32] == 0x45 and buf[33] == 0x54 and buf[34] == 0x41 and buf[35] == 0x2D and buf[36] == 0x49 and buf[37] == 0x4E and buf[38] == 0x46 and buf[39] == 0x2F and buf[40] == 0x6D and buf[41] == 0x6F and buf[42] == 0x7A and buf[43] == 0x69 and buf[44] == 0x6C and buf[45] == 0x6C and buf[46] == 0x61 and buf[47] == 0x2E and buf[48] == 0x72 and buf[49] == 0x73 and buf[50] == 0x61 then
    return {
      ext = 'xpi',
      mime = 'application/x-xpinstall'
    }
  end

  if buf[1] == 0x50 and buf[2] == 0x4B and (buf[3] == 0x3 or buf[3] == 0x5 or buf[3] == 0x7) and (buf[4] == 0x4 or buf[4] == 0x6 or buf[4] == 0x8) then
    return {
      ext = 'zip',
      mime = 'application/zip'
    }
  end

  if buf[258] == 0x75 and buf[259] == 0x73 and buf[260] == 0x74 and buf[261] == 0x61 and buf[262] == 0x72 then
    return {
      ext = 'tar',
      mime = 'application/x-tar'
    }
  end

  if buf[1] == 0x52 and buf[2] == 0x61 and buf[3] == 0x72 and buf[4] == 0x21 and buf[5] == 0x1A and buf[6] == 0x7 and (buf[7] == 0x0 or buf[7] == 0x1) then
    return {
      ext = 'rar',
      mime = 'application/x-rar-compressed'
    }
  end

  if buf[1] == 0x1F and buf[2] == 0x8B and buf[3] == 0x8 then
    return {
      ext = 'gz',
      mime = 'application/gzip'
    }
  end

  if buf[1] == 0x42 and buf[2] == 0x5A and buf[3] == 0x68 then
    return {
      ext = 'bz2',
      mime = 'application/x-bzip2'
    }
  end

  if buf[1] == 0x37 and buf[2] == 0x7A and buf[3] == 0xBC and buf[4] == 0xAF and buf[5] == 0x27 and buf[6] == 0x1C then
    return {
      ext = '7z',
      mime = 'application/x-7z-compressed'
    }
  end

  if buf[1] == 0x78 and buf[2] == 0x01 then
    return {
      ext = 'dmg',
      mime = 'application/x-apple-diskimage'
    }
  end

  if (buf[1] == 0x0 and buf[2] == 0x0 and buf[3] == 0x0 and (buf[4] == 0x18 or buf[4] == 0x20) and buf[5] == 0x66 and buf[6] == 0x74 and buf[7] == 0x79 and buf[8] == 0x70) or (buf[1] == 0x33 and buf[2] == 0x67 and buf[3] == 0x70 and buf[4] == 0x35) or (buf[1] == 0x0 and buf[2] == 0x0 and buf[3] == 0x0 and buf[4] == 0x1C and buf[5] == 0x66 and buf[6] == 0x74 and buf[7] == 0x79 and buf[8] == 0x70 and buf[9] == 0x6D and buf[10] == 0x70 and buf[11] == 0x34 and buf[12] == 0x32 and buf[17] == 0x6D and buf[18] == 0x70 and buf[19] == 0x34 and buf[20] == 0x31 and buf[21] == 0x6D and buf[22] == 0x70 and buf[23] == 0x34 and buf[24] == 0x32 and buf[25] == 0x69 and buf[26] == 0x73 and buf[27] == 0x6F and buf[28] == 0x6D) or (buf[1] == 0x0 and buf[2] == 0x0 and buf[3] == 0x0 and buf[4] == 0x1C and buf[5] == 0x66 and buf[6] == 0x74 and buf[7] == 0x79 and buf[8] == 0x70 and buf[9] == 0x69 and buf[10] == 0x73 and buf[11] == 0x6F and buf[12] == 0x6D) or (buf[1] == 0x0 and buf[2] == 0x0 and buf[3] == 0x0 and buf[4] == 0x1c and buf[5] == 0x66 and buf[6] == 0x74 and buf[7] == 0x79 and buf[8] == 0x70 and buf[9] == 0x6D and buf[10] == 0x70 and buf[11] == 0x34 and buf[12] == 0x32 and buf[13] == 0x0 and buf[14] == 0x0 and buf[15] == 0x0 and buf[16] == 0x0) then
    return {
      ext = 'mp4',
      mime = 'video/mp4'
    }
  end

  if (buf[1] == 0x0 and buf[2] == 0x0 and buf[3] == 0x0 and buf[4] == 0x1C and buf[5] == 0x66 and buf[6] == 0x74 and buf[7] == 0x79 and buf[8] == 0x70 and buf[9] == 0x4D and buf[10] == 0x34 and buf[11] == 0x56) then
    return {
      ext = 'm4v',
      mime = 'video/x-m4v'
    }
  end

  if buf[1] == 0x4D and buf[2] == 0x54 and buf[3] == 0x68 and buf[4] == 0x64 then
    return {
      ext = 'mid',
      mime = 'audio/midi'
    }
  end

  -- needs to be before the `webm` check
  if buf[32] == 0x6D and buf[33] == 0x61 and buf[34] == 0x74 and buf[35] == 0x72 and buf[36] == 0x6f and buf[37] == 0x73 and buf[38] == 0x6B and buf[39] == 0x61 then
    return {
      ext = 'mkv',
      mime = 'video/x-matroska'
    }
  end

  if buf[1] == 0x1A and buf[2] == 0x45 and buf[3] == 0xDF and buf[4] == 0xA3 then
    return {
      ext = 'webm',
      mime = 'video/webm'
    }
  end

  if buf[1] == 0x0 and buf[2] == 0x0 and buf[3] == 0x0 and buf[4] == 0x14 and buf[5] == 0x66 and buf[6] == 0x74 and buf[7] == 0x79 and buf[8] == 0x70 then
    return {
      ext = 'mov',
      mime = 'video/quicktime'
    }
  end

  if buf[1] == 0x52 and buf[2] == 0x49 and buf[3] == 0x46 and buf[4] == 0x46 and buf[9] == 0x41 and buf[10] == 0x56 and buf[11] == 0x49 then
    return {
      ext = 'avi',
      mime = 'video/x-msvideo'
    }
  end

  if buf[1] == 0x30 and buf[2] == 0x26 and buf[3] == 0xB2 and buf[4] == 0x75 and buf[5] == 0x8E and buf[6] == 0x66 and buf[7] == 0xCF and buf[8] == 0x11 and buf[9] == 0xA6 and buf[10] == 0xD9 then
    return {
      ext = 'wmv',
      mime = 'video/x-ms-wmv'
    }
  end

  if buf[1] == 0x0 and buf[2] == 0x0 and buf[3] == 0x1 and buf[4]:toString(16)[1] == 'b' then
    return {
      ext = 'mpg',
      mime = 'video/mpeg'
    }
  end

  if (buf[1] == 0x49 and buf[2] == 0x44 and buf[3] == 0x33) or (buf[1] == 0xFF and buf[2] == 0xfb) then
    return {
      ext = 'mp3',
      mime = 'audio/mpeg'
    }
  end

  if (buf[5] == 0x66 and buf[6] == 0x74 and buf[7] == 0x79 and buf[8] == 0x70 and buf[9] == 0x4D and buf[10] == 0x34 and buf[11] == 0x41) or (buf[1] == 0x4D and buf[2] == 0x34 and buf[3] == 0x41 and buf[4] == 0x20) then
    return {
      ext = 'm4a',
      mime = 'audio/m4a'
    }
  end

  -- needs to be before `ogg` check
  if buf[29] == 0x4F and buf[30] == 0x70 and buf[31] == 0x75 and buf[32] == 0x73 and buf[33] == 0x48 and buf[34] == 0x65 and buf[35] == 0x61 and buf[36] == 0x64 then
    return {
      ext = 'opus',
      mime = 'audio/opus'
    }
  end

  if buf[1] == 0x4F and buf[2] == 0x67 and buf[3] == 0x67 and buf[4] == 0x53 then
    return {
      ext = 'ogg',
      mime = 'audio/ogg'
    }
  end

  if buf[1] == 0x66 and buf[2] == 0x4C and buf[3] == 0x61 and buf[4] == 0x43 then
    return {
      ext = 'flac',
      mime = 'audio/x-flac'
    }
  end

  if buf[1] == 0x52 and buf[2] == 0x49 and buf[3] == 0x46 and buf[4] == 0x46 and buf[9] == 0x57 and buf[10] == 0x41 and buf[11] == 0x56 and buf[12] == 0x45 then
    return {
      ext = 'wav',
      mime = 'audio/x-wav'
    }
  end

  if buf[1] == 0x23 and buf[2] == 0x21 and buf[3] == 0x41 and buf[4] == 0x4D and buf[5] == 0x52 and buf[6] == 0x0A then
    return {
      ext = 'amr',
      mime = 'audio/amr'
    }
  end

  if buf[1] == 0x25 and buf[2] == 0x50 and buf[3] == 0x44 and buf[4] == 0x46 then
    return {
      ext = 'pdf',
      mime = 'application/pdf'
    }
  end

  if buf[1] == 0x4D and buf[2] == 0x5A then
    return {
      ext = 'exe',
      mime = 'application/x-msdownload'
    }
  end

  if buf[1] == 0x43 or buf[1] == 0x46 and buf[2] == 0x57 and buf[3] == 0x53 then
    return {
      ext = 'swf',
      mime = 'application/x-shockwave-flash'
    }
  end

  if buf[1] == 0x7B and buf[2] == 0x5C and buf[3] == 0x72 and buf[4] == 0x74 and buf[5] == 0x66 then
    return {
      ext = 'rtf',
      mime = 'application/rtf'
    }
  end

  if (buf[1] == 0x77 and buf[2] == 0x4F and buf[3] == 0x46 and buf[4] == 0x46) and ((buf[5] == 0x00 and buf[6] == 0x01 and buf[7] == 0x00 and buf[8] == 0x00) or (buf[5] == 0x4F and buf[6] == 0x54 and buf[7] == 0x54 and buf[8] == 0x4F)) then
    return {
      ext = 'woff',
      mime = 'application/font-woff'
    }
  end

  if (buf[1] == 0x77 and buf[2] == 0x4F and buf[3] == 0x46 and buf[4] == 0x32) and ((buf[5] == 0x00 and buf[6] == 0x01 and buf[7] == 0x00 and buf[8] == 0x00) or (buf[5] == 0x4F and buf[6] == 0x54 and buf[7] == 0x54 and buf[8] == 0x4F)) then
    return {
      ext = 'woff2',
      mime = 'application/font-woff'
    }
  end

  if (buf[35] == 0x4C and buf[36] == 0x50) and ((buf[9] == 0x00 and buf[10] == 0x00 and buf[11] == 0x01) or (buf[9] == 0x01 and buf[10] == 0x00 and buf[11] == 0x02) or (buf[9] == 0x02 and buf[10] == 0x00 and buf[11] == 0x02)) then
    return {
      ext = 'eot',
      mime = 'application/octet-stream'
    }
  end

  if buf[1] == 0x00 and buf[2] == 0x01 and buf[3] == 0x00 and buf[4] == 0x00 and buf[5] == 0x00 then
    return {
      ext = 'ttf',
      mime = 'application/font-sfnt'
    }
  end

  if buf[1] == 0x4F and buf[2] == 0x54 and buf[3] == 0x54 and buf[4] == 0x4F and buf[5] == 0x00 then
    return {
      ext = 'otf',
      mime = 'application/font-sfnt'
    }
  end

  if buf[1] == 0x00 and buf[2] == 0x00 and buf[3] == 0x01 and buf[4] == 0x00 then
    return {
      ext = 'ico',
      mime = 'image/x-icon'
    }
  end

  if buf[1] == 0x46 and buf[2] == 0x4C and buf[3] == 0x56 and buf[4] == 0x01 then
    return {
      ext = 'flv',
      mime = 'video/x-flv'
    }
  end

  if buf[1] == 0x25 and buf[2] == 0x21 then
    return {
      ext = 'ps',
      mime = 'application/postscript'
    }
  end

  if buf[1] == 0xFD and buf[2] == 0x37 and buf[3] == 0x7A and buf[4] == 0x58 and buf[5] == 0x5A and buf[6] == 0x00 then
    return {
      ext = 'xz',
      mime = 'application/x-xz'
    }
  end

  if buf[1] == 0x53 and buf[2] == 0x51 and buf[3] == 0x4C and buf[4] == 0x69 then
    return {
      ext = 'sqlite',
      mime = 'application/x-sqlite3'
    }
  end

  if buf[1] == 0x4E and buf[2] == 0x45 and buf[3] == 0x53 and buf[4] == 0x1A then
    return {
      ext = 'nes',
      mime = 'application/x-nintendo-nes-rom'
    }
  end

  if buf[1] == 0x43 and buf[2] == 0x72 and buf[3] == 0x32 and buf[4] == 0x34 then
    return {
      ext = 'crx',
      mime = 'application/x-google-chrome-extension'
    }
  end

  if (buf[1] == 0x4D and buf[2] == 0x53 and buf[3] == 0x43 and buf[4] == 0x46) or (buf[1] == 0x49 and buf[2] == 0x53 and buf[3] == 0x63 and buf[4] == 0x28) then
    return {
      ext = 'cab',
      mime = 'application/vnd.ms-cab-compressed'
    }
  end

  -- needs to be before `ar` check
  if buf[1] == 0x21 and buf[2] == 0x3C and buf[3] == 0x61 and buf[4] == 0x72 and buf[5] == 0x63 and buf[6] == 0x68 and buf[7] == 0x3E and buf[8] == 0x0A and buf[9] == 0x64 and buf[10] == 0x65 and buf[11] == 0x62 and buf[12] == 0x69 and buf[13] == 0x61 and buf[14] == 0x6E and buf[15] == 0x2D and buf[16] == 0x62 and buf[17] == 0x69 and buf[18] == 0x6E and buf[19] == 0x61 and buf[20] == 0x72 and buf[21] == 0x79 then
    return {
      ext = 'deb',
      mime = 'application/x-deb'
    }
  end

  if buf[1] == 0x21 and buf[2] == 0x3C and buf[3] == 0x61 and buf[4] == 0x72 and buf[5] == 0x63 and buf[6] == 0x68 and buf[7] == 0x3E then
    return {
      ext = 'ar',
      mime = 'application/x-unix-archive'
    }
  end

  if buf[1] == 0xED and buf[2] == 0xAB and buf[3] == 0xEE and buf[4] == 0xDB then
    return {
      ext = 'rpm',
      mime = 'application/x-rpm'
    }
  end

  if (buf[1] == 0x1F and buf[2] == 0xA0) or (buf[1] == 0x1F and buf[2] == 0x9D) then
    return {
      ext = 'Z',
      mime = 'application/x-compress'
    }
  end

  if buf[1] == 0x4C and buf[2] == 0x5A and buf[3] == 0x49 and buf[4] == 0x50 then
    return {
      ext = 'lz',
      mime = 'application/x-lzip'
    }
  end

  if buf[1] == 0xD0 and buf[2] == 0xCF and buf[3] == 0x11 and buf[4] == 0xE0 and buf[5] == 0xA1 and buf[6] == 0xB1 and buf[7] == 0x1A and buf[8] == 0xE1 then
    return {
      ext = 'msi',
      mime = 'application/x-msi'
    }
  end

  return nil
end

return fileType
