# USGS Earth Explorer Bulk Image Download Script (*Unofficial*)
*USGS offers a [Java-based bulk downloader](https://earthexplorer.usgs.gov/bulk), I created this tool because I could never get their tool to successfully complete.*

This script will help download large sets of images from the [USGS Earth Explorer Website](https://earthexplorer.usgs.gov/). You will need to [create an account](https://ers.cr.usgs.gov/register/) on Earth Explorer to download high-resolution assets.

## Requirements:

- `Bash shell`
- `curl`

## Usage:

Use the [USGS Earth Explorer Website](https://earthexplorer.usgs.gov/) to create your results set, and download the results as a CSV file.

Create a file called `secrets.txt` in the same directory as the `download-sat-images.sh` file. In the `secrets.txt` file enter your USGS username on the first line and your password on the second line.

The format of the command to issue is `./download-sat-images.sh (--OPTIONS) [CSV_FILE]`

The simplest usage of this script is to then execute `./download-sat-images.sh [CSV_FILE]` ie. `./download-sat-images.sh AERIAL_COMBIN_INDEX_442865.csv`. However, you will typically have to pass the line number to the script. This number should correspond to the number of the `Browse Link` column in the csv file. ie. `./download-sat-images.sh -l=36 AERIAL_COMBIN_INDEX_442865.csv`.

### Notes:

If you get a long list of malformed urls in the output, be certain you are passing the correct line number to the script. See help (`./download-sat-images.sh -h`) for more information.

Right now the `wget` version of this script is not functioning **attention any of you opensource contributors looking for something to do!**. `curl` is currently the only engine that works.