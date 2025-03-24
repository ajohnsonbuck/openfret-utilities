function writeZip(filename)
    zipfilename = strcat(filename,'.zip');
    zip(zipfilename,filename);
    delete(filename);
end