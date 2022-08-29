/*

*/

#if !defined(_RESEAU_H_)
#define _RESEAU_H_

#include <string>
#include <list>
#include <vector>
#include <map>
#include <queue>
#include <cmath>
#include "dateheure.h"
#include <unordered_map>
using namespace std;
extern double vitesse; // variable globale


class Borne{
public:
    const std::string getSID() const { return sid; }
private:
    int id;           // identifiant entier séquentiel
    std::string sid;  // identifiant string pour l'usager
    int puissance;    // en W
    long osmid;       // noeud OpenStreetMap le plus près (inutilisé pour TP5)
    std::map<int, double> bornesAtteignables; // arêtes sortantes : id borne --> distance en m

    mutable DateHeure tempDeplacement;
    mutable DateHeure tempDebutRecharge;
    mutable DateHeure tempApresRecharge;

    friend std::istream& operator>>(std::istream&, Borne&);
    friend class Reseau;
};

typedef std::pair<std::string, DateHeure> Min;
struct Compare {
    bool operator()(Min a, Min b) {
        return a.second > b.second;
    }
};

class Vehicule{
    std::string sdepart,  // id string de la borne de départ
    sarrivee; // et d'arrivée
    DateHeure datedepart;
    double batterie;      // capacité en Wh
    double consommation;  // unité Wh/m
    double autonomie=0;   // unité m (calculé = batterie/consommation)

    friend std::istream& operator>>(std::istream&, Vehicule&);
    friend bool operator<( const Vehicule& v1, const Vehicule& v2 ) { return v1.datedepart < v2.datedepart; }
    friend class Reseau;
};

// typedef permet de spécifier un nouveau type à partir d'un autre.
typedef std::vector<Vehicule> Requete;

std::istream& operator>>(std::istream&, Requete&);

// La structure Etape représente une étape dans un plan.
// Il s'agit d'un ID string d'une borne et des temps correspondants.
struct Etape{
    std::string borne = "?";
    DateHeure arrivee, debut, fin;
    friend std::ostream& operator<<(std::ostream&, const Etape&);
};

typedef std::list<Etape> PlanVehicule;

// PlanFlotte hérite de std::vector<PlanVehicule>
struct PlanFlotte : public std::vector<PlanVehicule> {
    DateHeure max() const;
};

std::ostream& operator<<(std::ostream&, const PlanVehicule&);
std::ostream& operator<<(std::ostream&, const PlanFlotte&);


class Reseau{
public:
    // Les 3 fonctions suivantes sont les points d'entrées.
    // La fonction main du TP5 appelle l'une d'elles.
    PlanFlotte calculerN1(const Requete& r) ;
    PlanFlotte calculerN2(const Requete& r) ;
    PlanFlotte calculerN3(const Requete& r) ;

private:
    std::vector<Borne> bornes;
    std::unordered_map<std::string, int> indexbornes; // ID string --> ID séquentiel 0, 1, 2,...

    PlanVehicule calculer(const Vehicule& v) ;

    friend std::istream& operator>>(std::istream&, Reseau&);
    unordered_map<int,map<DateHeure,DateHeure>> reservation;
    DateHeure prendreDateValide(map<DateHeure, DateHeure> reservations,DateHeure debut, DateHeure fin) const;


};



#endif