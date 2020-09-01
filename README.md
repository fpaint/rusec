# Rusec
Extraction script for lib.rus.ec library archive I've got from torrent. 

I have an 8-years old nepheu and once I wanted to give him a library rich enough to choose from. I've not found already prepared children library on torrents, so I needed to make it by myself. At first I've tried to parse Flibusta OPDS catalog, it was not hard. But as file downloading from Flibusta is sluggish, it would take an eternity to get the all. 

The second attempt was more successful. I've got lib.rus.ec archive from torrent. It's just a bunch of monthly incremental zip-archives with originally formatted index in .inpx file and a special Delphi written application called MyHomeLib to read it. Without any ability to take just one category and leave the rest. So I've made this script to parse the index, extract all the children books and arrange them into "genre/author/title" folder structure. 

## Using

If you want to repeat this expirence, you need to find and download lib.rus.ec library from torrents at first (I do not give a link here for obvious reasons). Then clone this repositary, change the `input_path` and `output_path` in `build.rb` for your requirements, and finally run the `build.rb`. You also free to remove the "children genres only" condition or replace it with your prefered genres. Keep screaming "Yarrrr!" loudly while script working for better performance. 

## What's new

* Fix folder names ended with point. I've found they can't be readed in Windows. 
* Contents generation
