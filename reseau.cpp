#include <cassert>
#include <iostream>
#include <algorithm>
#include "reseau.h"
using namespace std;



PlanFlotte Reseau::calculerN1(const Requete& r) {
    PlanFlotte plan;
    for(const Vehicule& v : r)
        plan.push_back(calculer(v));
    return plan;
}



PlanFlotte Reseau::calculerN2(const Requete& r){
    PlanFlotte plan;


    for(const Vehicule& v : r){
        PlanVehicule pv = calculer(v);
        plan.push_back(pv);
        //À compléter: réserver les bornes pour pv
        for(const Etape& eta: pv){
            reservation[indexbornes.find(eta.borne)->second][eta.debut] = eta.fin;
        }
    }
    reservation.clear();
    //À compléter: il faut annuler les réservations
    return plan;
}




PlanFlotte Reseau::calculerN3(const Requete& r) {
    std::vector<Vehicule> req = r;
    PlanFlotte plan;
    DateHeure dateHeure = std::numeric_limits<int>::max();
    PlanFlotte final;
    std::sort(req.begin(), req.end());
    do{
        //cout << req[0].datedepart << " " << req[1].datedepart << " " <<req[2].datedepart << " " <<req[3].datedepart << endl;
        for(const Vehicule& v : req){
            PlanVehicule pv = calculer(v);
            plan.push_back(pv);
            //À compléter: réserver les bornes pour pv
            for (const Etape &eta: pv) {
                reservation[indexbornes.find(eta.borne)->second][eta.debut] = eta.fin;
            }
        }
        reservation.clear();
        if(plan.max() < dateHeure){
            final.clear();
            for(const PlanVehicule& pv : plan) {
                final.insert(final.begin(),pv);
            }
            dateHeure = plan.max();
        }
        plan.clear();
    } while (std::next_permutation(req.begin(),req.end()));


    return final;
}



PlanVehicule Reseau::calculer(const Vehicule& v) {
    int id_borne_depart = indexbornes[v.sdepart];
    int id_borne_arrivee = indexbornes[v.sarrivee];
    PlanVehicule pv;

    if(id_borne_depart==id_borne_arrivee)
        pv.push_back(Etape{v.sdepart, v.datedepart, v.datedepart, v.datedepart});
    else{
        //Algo de Dijkstra
        unordered_map<std::string , DateHeure> distances;
        unordered_map<std::string, std::string> parents;
        std::priority_queue<Min, vector<Min>,Compare> prioBorne;

        std::map<int, double>::const_iterator iterator = bornes.at(indexbornes.find(v.sdepart)->second).bornesAtteignables.begin();
        for(;iterator != bornes.at(indexbornes.find(v.sdepart)->second).bornesAtteignables.end();++iterator){
            std::string parent = bornes.at(iterator->first).getSID();
            distances[parent] = numeric_limits<int>::max();
            parents[parent];
        }
        distances[v.sdepart] = v.datedepart;
        parents[v.sdepart] = "";
        prioBorne.push(make_pair(v.sdepart,0));

        while(!prioBorne.empty()){
            Min v1 = prioBorne.top();
            prioBorne.pop();
            if(distances[v1.first] == numeric_limits<int>::max())
                break;
            Borne borne = bornes.at(indexbornes.find(v1.first)->second);
            for( const pair<int,double>& arete :borne.bornesAtteignables){
                if(arete.second <= v.autonomie) {
                    Borne enfant1 = bornes.at(arete.first);

                    DateHeure tempArriver =  distances[borne.getSID()] + std::ceil(arete.second/vitesse);
                    DateHeure tempDebut = tempArriver;
                    double energieConsomer = arete.second * v.consommation;
                    DateHeure tempFinRecharge = tempDebut + std::ceil((energieConsomer*3600) / enfant1.puissance);

                    DateHeure ecartDebutFin = tempFinRecharge - tempDebut;
                    //pour n2: s'il y a reservation décaler et trouver prochain trou.
                    tempDebut = prendreDateValide(reservation[arete.first],tempDebut,tempFinRecharge);
                    tempFinRecharge = tempDebut + ecartDebutFin;

                    if (tempFinRecharge < distances[enfant1.getSID()]) {
                        distances[enfant1.getSID()] = tempFinRecharge;
                        parents[enfant1.getSID()] = bornes.at(indexbornes.find(v1.first)->second).getSID();
                        bornes.at(arete.first).tempDeplacement = tempArriver;
                        bornes.at(arete.first).tempDebutRecharge = tempDebut;
                        bornes.at(arete.first).tempApresRecharge = tempFinRecharge;
                        prioBorne.push(make_pair(enfant1.getSID(), tempFinRecharge));
                    }
                }
            }
        }

        std::string actuel = v.sarrivee;
        while(actuel != ""){
            if(actuel == v.sdepart){
                pv.push_front(Etape{actuel,v.datedepart,v.datedepart,v.datedepart});
            }else{
                Borne borne = bornes.at(indexbornes.at(actuel));
                pv.push_front(Etape{actuel,borne.tempDeplacement,borne.tempDebutRecharge,borne.tempApresRecharge});
            }
            actuel = parents[actuel];
        }
    }
    return pv;
}
DateHeure Reseau::prendreDateValide( map<DateHeure, DateHeure> reservations,DateHeure debut, DateHeure fin)const {
    map<DateHeure, DateHeure>::iterator iter = reservations.lower_bound(debut);
    if(iter != reservations.begin())
        --iter;

    DateHeure duree = fin - debut;
    if(iter == reservations.end() && !reservations.empty())
        iter = reservations.begin();

    while (iter != reservations.end()){
        if((debut+duree) <= iter->first){
            return debut;
        }
        else {
            if(iter->first < debut){
                if((iter->second) >= debut) {
                    debut = iter->second;
                }
            }else{
                debut = iter->second;
            }
            ++iter;
        }
    }
    return debut;
}

DateHeure PlanFlotte::max() const{
    DateHeure max;
    for(PlanVehicule pv : *this)
        if(!pv.empty() && pv.back().fin > max)
            max = pv.back().fin;
    return max;
}
