# NSP Python potential matches
# Developed by Ben Vagle and Gayeong Song
# Comically large NSP class
class Nspclass:

    def __init__(self, number, X, Province, DistrictNsp, FP, Phase, Category, CDCcode, CDCnameNsp, villagelist, families, financed, closed, disbursed, electiondate, firstdisbdate, lastdisbdate, ID_nsp, certainty):

        self.number = number
        self.X = X
        self.Province = Province
        self.DistrictNSP = DistrictNsp
        self.FP = FP
        self.Phase = Phase
        self.Category = Category
        self.CDCcode = CDCcode
        self.CDCnameNsp = CDCnameNsp
        self.villagelist = villagelist
        self.families = families
        self.financed = financed
        self.closed = closed
        self.disbursed = disbursed
        self.electiondate = electiondate
        self.firstdisbdate = firstdisbdate
        self.lastdisbdate = lastdisbdate
        self.ID_nsp = ID_nsp
        self.certainty = certainty

    def __str__(self):
        return str(self.number) + "," + str(self.X) + ',' + str(self.Province) + ',' + str(self.DistrictNSP) + ',' + str(self.FP) + ',' + str(self.Phase) + ',' + str(self.Category) + ',' + str(self.CDCcode) + "," + str(self.CDCnameNsp) + ',' + str(self.villagelist) + "," +  str(self.families) + ',' + str(self.financed) + "," +  str(self.closed) + "," +  str(self.disbursed) + "," +  str(self.electiondate) + "," +  str(self.firstdisbdate) + "," +  str(self.lastdisbdate) + "," +  str(self.ID_nsp) + "," +  str(self.certainty)