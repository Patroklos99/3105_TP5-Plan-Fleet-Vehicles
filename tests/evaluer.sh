#!/bin/bash
#####################################################################################
# UQAM - Département d'informatique
# INF3105 - Structures de données et algorithmes
# TP5
# http://ericbeaudry.ca/INF3105/tp5/
#
# Script d'évaluation
#
# Instructions:
# 1. Déposer ce script avec les fichiers problèmes dans un répertoire
#    distinct (ex: tests).
# 2. Étudiants : Se placer dans le répertoire contenant votre programme
#    Correcteur : Se placer dans répertoire contenant les soumissions Oto.
# 3. Lancer ce script (ex: ../tests/evaluer.sh).
#####################################################################################

echo "Évaluation du TP5 d'INF3105..."

# Répertoire contenant les fichiers tests
repertoire_tests=`dirname $0`
# Régions à tester
regions="uqam ipe maritimes quebec"

if [ `pwd` -ef $repertoire_tests ];
then
    echo "Ce script doit être dans un répertoire différent de celui contenant votre programme tp3."
    echo "Ce script a été arrêté afin de ne pas écraser les fichiers de résultat *-req+.txt."
    exit -2;
fi

########### Détection du valideur de résultats #######
# Le valideur à utiliser
valideur="${repertoire_tests}/valideur"
if [ -x "${valideur}-`uname`-`uname -m`" ]
then
    valideur="${valideur}-`uname`-`uname -m`"
else
    if [ -x "${valideur}-`uname`" ]
    then
        valideur="${valideur}-`uname`"
    fi
fi
######################################################
#if [ ${repertoire_tests}/valideur.cpp -nt ${valideur} ]
#then
#    echo "Compilation du valideur..."
#    g++ -o ${valideur} ${repertoire_tests}/valideur.cpp -O1
#fi
######################################################

# Détection si l'utilitaire time sous Linux est disponible (peut afficher 0.00)
# Sous Debian/Ubuntu : apt-get install time
if [ -x /usr/bin/time ] ; then
    echo "Détection et test de /usr/bin/time :"
    /usr/bin/time -f %U echo 2>&1 > /dev/null
    utilitairetime=$?
else
    echo "Sous Debian/Ubuntu, essayez: apt-get install time"
    utilitairetime="-1"
fi


# Limiter le temps d'exécution (120 secondes = 2 minutes), la quantite de mémoire (4Go), et l'écriture sur disque (8 Mo)
ulimit -t 120 -v 4194304 -f 8192
echo "Limite de temps par test : `ulimit -t` secondes."
echo "Limite de mémoire par test : `ulimit -v` KiO."
echo "Limite de taille de fichier : `ulimit -f` KiO."


# Détection du CPU
if [ -e /proc/cpuinfo ] ; then
    cpuinfo=`grep "model name" /proc/cpuinfo | sort -u | cut -d ":" -f 2`
else
    cpuinfo="?"
fi



##### Fonction d'évaluation d'un TP ######
function EvaluerTP
{
    date2=`date +%Y%m%d_%H%M%S`
    logfile="log.txt"
    echo "Les résultats seront déposés dans $logfile..."
    echo "Date: $date2" > $logfile

    #datesoumis=`grep Date lisezmoi.txt| cut -c 7-`
    #coequipier=`grep Coéquipier lisezmoi.txt| cut -d : -f 2`
    #heures=`grep Heures lisezmoi.txt| cut -d : -f 2`
    #autoeval=`grep Auto-Évaluation lisezmoi.txt| cut -d : -f 2`

    ## ZIP
    #if [ -f sources.zip ]; then
    #    echo "Unzip: sources.zip"
    #    unzip -n sources.zip
    #    rm sources.zip
    #fi

    #echo "Fichiers:" > $logfile
    #ls -l 2>&1 | tee -a $logfile

    ## Forcer la recompilation.
    #rm tp5 *.o
    #make clean

    echo "#CPU :$cpuinfo"  | tee -a $logfile
    #echo "#Date début : ${date2}"  | tee -a $logfile
    echo "#Limite de `ulimit -t` secondes par test"  | tee -a $logfile
    echo | tee -a $logfile
    
    # Pour statistiques : nombre de lignes de code...
    #echo "Taille des fichiers source :" | tee -a ${logfile}
    #wc *.{c*,h*}  | tee -a ${logfile}

    taille=`wc *.{c*,h*} | grep total`
    sommaire="$taille"
    sommaire="$datesoumis\t$coequipier\t$autoeval\t$heures\t$taille\t"
    
    #echo "Compilation ..." | tee -a $logfile 
    #make tp4 >> $logfile 2>&1
    if [ ! -x tp5 ]
	    then
	    echo " Erreur : le fichier tp5 n'existe pas ou n'est pas exécutable!"
	    return
    fi

    echo | tee -a $logfile

    echo -e "#Fichier-Test\tCPU\tMém(k)\tN1\tN2\tN3\t/\tNbRes\t/\t/NbReq" >> $logfile
    echo -e  "Fichier-Test\tCPU\tMém(k)\tN1\tN2\tN3\t/\tNbRes\t/\t/NbReq"

    # Itérer sur toutes les régions
    for region in ${regions};
    do
        #fcarte="${repertoire_tests}/${region}-carte.txt"
        #fbornes="${repertoire_tests}/${region}-bornes.txt"
        fgbornes="${repertoire_tests}/${region}-gbornes.txt"

        # Lister les fichiers requêtes pour la region
        tests="`cd $repertoire_tests && ls ${region}-req?.txt`"

        # Itérer sur tous les tests
        for test in $tests; do
            nblignes=`cat $repertoire_tests/$test | wc -l`

            if [ $utilitairetime -eq 0 ]; then
                t=`(/usr/bin/time -f "%U\t%M" ./tp5 $fgbornes < $repertoire_tests/$test > ${test%.txt}+.txt) 2>&1 | tail -n 1`
            else
                t=`(time -p ./tp5 $fgbornes < $repertoire_tests/$test > ${test%.txt}+.txt) 2>&1 | egrep user | cut -f 2 -d " "` 
            fi

            if ( [ -x ${valideur} ] ); then
                validation=`${valideur} $fgbornes $repertoire_tests/${test} ${test%.txt}+.txt ${repertoire_tests}/${test%.txt}+.txt | tail -n 1`
            else
                validation=""
            	if( [ -e ${repertoire_tests}/${test%.txt}+.txt ] ); then
                	diff -tibw ${test%.txt}+.txt ${repertoire_tests}/${test%.txt}+.txt 2>&1 > /dev/null
            		if [ $? -eq 0 ]; then
            	    	validation="OK"
             		else
             	    	validation="Different"
            		fi
            	fi
            fi

            echo -e "${test}\t${t}\t${validation}"
            echo -e "${test}\t${t}\t${validation}" >> $logfile
            sommaire="${sommaire}\t\t${t}\t${validation}"
        done

    done
}

if [ -f Makefile ];
then
    tps="."
else
    # Lister les répertoires
    tps=`ls -1`
    tps=`for x in $tps; do if [ -d $x ]; then echo $x; fi; done`
fi

# Génération de l'entête du rapport
date=`date +%Y%m%d_%H%M%S`
echo "#Rapport de correction INF3105 / $programme" > "rapport-${date}.txt"
echo -e "#Date:\t${date}" >> "rapport-${date}.txt"
echo -e "#Machine :\t" `hostname` >> "rapport-${date}.txt"
echo -e "#CPU :\t$cpuinfo" >> "rapport-${date}.txt"
echo >> "rapport-${date}.txt"

# Génération des titres des colonnes
echo -e -n "#\t\t\t" >> "rapport-${date}.txt"
for carte in ${cartes};
do
    tests="`cd $repertoire_tests && ls ${carte}-re*[^+].txt`"
    for test in $tests;
    do
        echo -e -n "$test\t\t\t\t\t\t\t\t\t\t\t" >> "rapport-${date}.txt"
    done
done
echo >> "rapport-${date}.txt"

echo -e -n "#Soumission\tTaille sources" >> "rapport-${date}.txt"
for carte in ${cartes};
do
    tests="`cd $repertoire_tests && ls ${carte}-req*[0-9B].txt`"
    for test in $tests;
    do
        echo -e -n "\t\tCPU\tMém(k)\tDurOK\tChOK\t0B\t1B\t2+B\tBorOK\t/\tNbReq" >> "rapport-${date}.txt"
    done
done
echo >> "rapport-${date}.txt"

# Itération sur chaque TP
for tp in $tps; do
    sommaire=""
    echo "## ÉVALUATION : $tp"
    pushd $tp
    	EvaluerTP
	#Nettoyer
    popd
    #echo -e ">> ${sommaire}"
    echo -e "${tp}\t${sommaire}" >> "rapport-${date}.txt"
done


