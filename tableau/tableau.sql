-- 
-- Šitomis užklausomis iš žalių duomenų sudedamas duomenų rinkinys Tableau. Esminis laukas, kuris paskaičiuojamas: nuomos_kaina
-- Jeigu sklypai_skaiciavimai nėra sutampančio sklypo_id ir objekto_id, tai nuomos_kaina lieka NULL 
-- (bet tai ne įrodymas, kad sklypas nuomojamas už dyką)
-- 

update sklypai_tableau st join

(select 
	oid, s.`Moketojo_pavadinimas`, s.`Sklypo_adresas`,
	round(sum(ss.`Suma`)/3.4528, 2) as sumoketa, pp, coalesce(ss.`ND_plotas`, ss.Plotas) plotas, ss.`Paslaugos_pabaiga` as ppb
from sklypai s 
	join sklypai_skaiciavimai ss 
		on s.`Sklypo_ID`=ss.`Sklypai_ID` 
			and s.`Objekto_ID`=ss.`Objektai_ID`
	join (select
				s.`Sklypo_ID` sid, s.`Objekto_ID` oid, max(ss.paslaugos_pradzia) pp
		  from sklypai s 
			  join sklypai_skaiciavimai ss 
					on s.`Sklypo_ID`=ss.`Sklypai_ID` 
						and s.`Objekto_ID`=ss.`Objektai_ID`
		  group by s.objekto_id
		) maxs
		on maxs.sid=s.Sklypo_ID and maxs.oid = s.`Objekto_ID` and maxs.pp=ss.paslaugos_pradzia
group by s.objekto_id) foo on foo.oid=st.`Objekto_ID`

set st.suma=foo.sumoketa, st.`sumos_pradzia` = foo.pp, st.`nuomos_plotas` = foo.plotas, st.`sumos_pabaiga` = foo.ppb;

update sklypai_tableau st set st.`nuomos_kaina` = (st.`suma` / coalesce(datediff(st.`sumos_pabaiga`, st.`sumos_pradzia`)/365, 1)) / st.`nuomos_plotas`;

-- 
-- Pagrindinė Tableau užklausa, iš kurios piešiami duomenys žemėlapyje
-- 

select 
    coalesce(st.Sklypo_adresas, 'Be adreso') as Adresas,
    coalesce(st.Moketojo_pavadinimas, 'Be pavadinimo') as Nuomininkas,
    coalesce(st.Naudojimo_pradzia, 'Nenurodyta') as Naudojimo_pradzia, 
    coalesce(st.Naudojimo_pabaiga, 'Nenurodyta') as Naudojimo_pabaiga,
    coalesce(st.nuomos_plotas, st.Plotas*st.Skaitiklis / st.Vardiklis) as Nuomojamas_plotas, 
    round(st.nuomos_kaina, 2) as kaina,
    st.lat, 
    st.lon
from sklypai_tableau st
where st.lat is not null