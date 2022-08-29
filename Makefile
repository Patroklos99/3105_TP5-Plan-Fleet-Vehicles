# Makefile pour INF3105 / TP5
OPTIONS = -Wall

#Si ancien GNU gcc (g++), il peut être nécessaire d'ajouter -std=c++11

# Choisir l'une des deux configurations : -g -O0 pour débogage et -O2 pour la remise.
#OPTIONS = -g -O0 -Wall
OPTIONS = -O2 -Wall

# Syntaxe : cible : dépendance1 dépendance2 ...
# Ensuite, la ou les ligne(s) débutant par une tabulation (\t) donne les commandes pour construire une cible

tp5 :  tp5.o reseau.o dateheure.o es.o
	g++ ${OPTIONS} -o tp5 tp5.o reseau.o dateheure.o es.o

tp5.o: tp5.cpp reseau.h dateheure.h
	g++ ${OPTIONS} -c tp5.cpp

reseau.o: reseau.cpp reseau.h dateheure.h
	g++ ${OPTIONS} -c reseau.cpp

es.o: es.cpp reseau.h dateheure.h
	g++ ${OPTIONS} -c es.cpp

dateheure.o: dateheure.cpp dateheure.h
	g++ ${OPTIONS} -c dateheure.cpp

clean:
	rm -rf tp5 *.o ipe-req*+.txt maritimes-req*.txt quebec-req*+.txt rapport-20*.txt uqam-req*+.txt uqam-resultat*.txt 
