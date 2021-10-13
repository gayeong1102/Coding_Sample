# NSP Python potential matches
# Developed by Ben Vagle and Gayeong Song
# Program Purpose: Writes a modified outfile with definitvely matched NSP / aid names, and a list of potential aid names for each NSP name in a column next to original NSP name.

# Note - Made some modifications to the NSP / AID classes for Samangan because the data is ordered in a different way on this spreadsheet.

# Operating Procedure: 

# A) Be sure to check that your nsp_2 and aid_2 files line up with the classes for nsp and aid, sometimes the CSVs are formatted in marginally inconsistent ways. 
# B) Be sure to remove all commas from the original csv documents. E.g. 1,000 must be written as 1000. This can be done through formatting in excel or a replace all command. 
# C) Be sure that the .txt files you are using are formatted similarly, often, .txt files converted from a CSV are wrapped in quotation marks. If aid_2.txt is wrapped in quotations and nsp_2.txt isn't, fuzzywuzzy won't be able to match them!

from fuzzywuzzy import fuzz
from aidclass import Aidclass
from nspclass import Nspclass
from ratioclass import Ratioclass


# Read in for all aid class values.
def read_in_aid():
    # change directory as needed, we want the province aid_2.txt here.
    in_file = open("/Users/benvagle/PycharmProjects/Pajhwok Casualty/Fuzz/samangan/samangan_aid_2.txt")

    aidlist = []

    for line in in_file:
        line = line.strip()
        line = line.split(",")
        t = Aidclass(str(line[9]), str(line[2]))
        aidlist.append(t)
    in_file.close()
    return aidlist


# Read in for all NSP values.
def read_in_nsp():
    # change directory as needed, we want the province nsp_2.txt here.
    in_file = open("/Users/benvagle/PycharmProjects/Pajhwok Casualty/Fuzz/samangan/samangan_nsp_2.txt")

    nsplist = []

    # Reference that helps with understanding the order of this convuluted class. 
    
    #     return str(self.number) + "," + str(self.X) + ',' + str(self.Province) + ',' + str(self.DistrictNSP) + ',' + str(
    #     self.FP) + ',' + str(self.Phase) + ',' + str(self.Category) + ',' + str(self.CDCcode) + "," + str(
    #     self.CDCnameNsp) + "," + str(self.families) + ',' + str(self.financed) + "," + str(self.closed) + "," + str(
    #     self.disbursed) + "," + str(self.electiondate) + "," + str(self.firstdisbdate) + "," + str(
    #     self.lastdisbdate) + "," + str(self.ID_nsp) + "," + str(self.certainty) + "," + str(self.villagelist)

    # I make a counter here just so we can have a sane column name for row 0
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




