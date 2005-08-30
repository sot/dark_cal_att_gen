objects = attitude.pl index.html dark_attitudes.dat table_17.csv

webloc = /proj/sot/ska/www/ASPECT/dark_att_generator/

doc: $(objects)
	pod2html attitude.pl > dark_cal_help.html

install: $(objects) dark_cal_help.html
	rsync -v --times --cvs-exclude $(objects) dark_cal_help.html $(webloc)

test: $(objects) t/test_ATTList_2005001 t/test_ORList_2005001
	./attitude.pl date="2005:001" type="ATT List" z_low="0" z_up="250" > new_test_ATTList
	./attitude.pl date="2005:001" type="OR List" z_low="0" z_up="250"  > new_test_ORList
	diff new_test_ATTList t/test_ATTList_2005001
	diff new_test_ORList t/test_ORList_2005001

