objects = attitude.pl dark_attitudes.dat table_17.csv

test: 

doc: 

install: $(objects)
	rsync --times --cvs-exclude $(objects) /proj/sot/ska/www/ASPECT/dark_att_generator/
	wget -O index.html http://asc.harvard.edu/mta/ASPECT/dark_att_generator/attitude.pl
	rsync --times --cvs-exclude index.html /proj/sot/ska/www/ASPECT/dark_att_generator/

#	pod2html task.pl > $(INSTALL_DOC)/doc.html
