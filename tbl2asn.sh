# Proper way to create an asn from a prokka annotation for a metagenome

/home/robert/Tools/linux64.tbl2asn \
-i PROKKA_03022019_renamed.fna \
-f PROKKA_03022019_fixed_v1.tbl \
-t ../SDC9.template.sbt -o PROKKA_SDC9_fixed_v2.asn -V vbt \
-s T -m b -l paired-ends -a r10k -W T -o SDC9.asn \
-y 'Annotated using prokka 1.13.3 from https://github.com/tseemann/prokka' \
-j "[organism=bioreactor metagenome] [gcode=11]"
