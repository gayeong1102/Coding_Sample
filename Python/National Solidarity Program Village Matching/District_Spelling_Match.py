# District Spelling Match / Replace

from fuzzywuzzy import fuzz
from aidclass import Aidclass
from nspclass import Nspclass
from ratioclass import Ratioclass

def read_in_aid():
    # change directory as needed, we want the province aid_2.txt here.
    in_file = open("/Users/gayeongsong/Desktop/badakhshan_aid_raw.txt")

    aidlist = []

    for line in in_file:
        line = line.strip()
        line = line.split(",")
        t = Aidclass(str(line[9]), str(line[2]))
        aidlist.append(t)
    in_file.close()
    return aidlist


def read_in_nsp():
    # change directory as needed, we want the province nsp_2.txt here.
    in_file = open("/Users/gayeongsong/Desktop/badakhshan_nsp_raw.txt")

    nsplist = []

    count = 0
    for line in in_file:
        line = line.strip()
        line = line.split(",")

        # Column creation if statement
        if count == 0:
            t = Nspclass(str(line[0]), 'X', str(line[1]), str(line[2]), str(line[3]), str(line[4]), str(line[5]),
                         str(line[6]), str(line[7]), 'Matches', str(line[8]), str(line[9]), str(line[10]),
                         str(line[11]), str(line[12]), str(line[13]), str(line[14]), str(line[15]), str(line[16]))
            count = count + 1

        # This is a complete nightmare, but it works
        else:
            t = Nspclass(str(line[0]), 'None', str(line[1]), str(line[2]), str(line[3]), str(line[4]), str(line[5]),
                         str(line[6]), str(line[7]), 'None', str(line[8]), str(line[9]), str(line[10]), str(line[11]),
                         str(line[12]), str(line[13]), str(line[14]), str(line[15]), str(line[16]))

        nsplist.append(t)
    in_file.close()
    return nsplist

aidlist = read_in_aid()
nsplist = read_in_nsp()

loopcount = 0

for x in nsplist:

    if loopcount !=0:

        districtlist = []

        districtstring = ''

        for y in aidlist:

            if x.DistrictNSP == y.districtAid:
                continue

            else:
                Ratio = fuzz.ratio(x.DistrictNSP.lower(), y.districtAid.lower())

                if Ratio >= 55:
                    districtlist.append(Ratioclass(y.districtAid.lower(), Ratio))





# Large forloop that matches potential AID names to NSP and replaces NSP names with clear aid matches.

# Loopcount is used so program does not run on row 0.
loopcount = 0

for x in nsplist:
    if loopcount != 0:

        # List of all potential name matches.
        villagelist = []

        # The final string of potential names that is returned for each value of x in nsplist.
        finalstring = ''

        # Loop through all values in aid.
        for y in aidlist:

            # We match if district is the same, and if potential name matches have a Levenstein ratio above 55.
            if x.DistrictNSP == y.districtAid:
                Ratio = fuzz.ratio(x.CDCnameNsp.lower(), y.CDCnameAid.lower())

                if Ratio >= 55:
                    villagelist.append(Ratioclass(y.CDCnameAid, Ratio))

        # Repeats cycle if nothing found under stricter criteria. Goes down to 48, which basically provides a suggestion for every single column.
        # In general, these aren't terribly accurate. This may signal a lack of obvious text matches in general. Falling Rain may be a good fallback here.
        if len(villagelist) == 0:

            # Loop through all values in aid.
            for y in aidlist:
                if x.DistrictNSP == y.districtAid:
                    Ratio = fuzz.ratio(x.CDCnameNsp.lower(), y.CDCnameAid.lower())
                    if Ratio >= 48:
                        villagelist.append(Ratioclass(y.CDCnameAid, Ratio))

        # Reverse sort of village list.
        villagelist.sort(key=lambda x: x.Ratio, reverse=True)

        # This loop goes into the code and replaces all CDC names with their very likely matches (Levenstein Ratio of above 75)
        for i in range(len(villagelist)):
            if i == 0:
                if villagelist[i].Ratio > 75:
                    # Reason that MATCHED wasn't showing up is bc villagelist is a list of objects!
                    # Instead, we will set the first value of finalstring to matched.
                    finalstring = "MATCHED | Original was: " + str(x.CDCnameNsp)
                    x.CDCnameNsp = villagelist[i].CDCname

                    # Finally, this loop creates a 'final string' that is a compilation of all potential matches with their Levenstein ratio in parentheses.
        for i in range(len(villagelist)):

            # If final string has no value we format initially like this.
            if len(finalstring) != 0:
                finalstring = str(finalstring) + '; ' + str(
                    str(villagelist[i].CDCname + ' ' + '(' + str(villagelist[i].Ratio)) + ')')

            # If final string has some prior value we append values to it in this manner.
            else:
                finalstring = str(finalstring) + str(
                    str(villagelist[i].CDCname + ' ' + '(' + str(villagelist[i].Ratio)) + ')')

        # Lists have an annoying habit of wrapping quotes around strings, we get rid of those quotes here.
        finalstring = finalstring.replace('"', '')

        # Assuming we find anything for finalstring, the value of villagelist is changed from 'None' to the value of finalstring.
        if len(finalstring) != 0:
            x.villagelist = finalstring

    # quick if statement to stop loop count once it serves initial function
    if loopcount == 0:
        loopcount = loopcount + 1


def createoutfile(nsplist, newfilename):
    out_file = open(newfilename, "w")
    for i in range(len(nsplist)):
        out_file.write(str(nsplist[i]) + "\n")
    out_file.close()


createoutfile(nsplist, "NSP Samangan Fuzz Matched.txt")
