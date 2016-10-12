number of prteins per family

SELECT hpkd_group,hpkd_family, count(hpkd_family) as famcount FROM hpkd GROUP BY hpkd_group,hpkd_family ORDER BY hpkd_group,famcount DESC
