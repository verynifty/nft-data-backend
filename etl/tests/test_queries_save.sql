select
      * 
    from
      (
      select
        *
      from
        generate_series(${range_start}, ${range_end}) as blocknumber
    where
    blocknumber not in (
      select
        block_number 
      from
        block
        )) as t



   select
      * 
    from
      (
      select
        *
      from
        generate_series(14219155, 14229155) as blocknumber
    where
    blocknumber not in (
      select
        block_number 
      from
        block
        )) as t


   select max(b.block_number) from block b 


   select * from block where block_number = 5354180


   // 14229847
   // 13247921

   select
      * 
    from
      (
      select
        *
      from
        generate_series(0, 1429155) as blocknumber
    where
    blocknumber not in (
      select
        block_number 
      from
        block
        )) as t



// double check fake
           select
      * 
    from
      (	
      select
        *
      from
        generate_series(100000, 110000000) as blocknumber
    where
    blocknumber not in (
      select
        block_number 
      from
        block
        )) as t




        select
	count(*)
from
	(
	select
		graphile_worker.add_job(
        'nft_update',
		json_build_object(
          'address', address,
          'tokenId', token_id::text,
          'force', true
        ),
		job_key := CONCAT('nftupdate_', address, '_', token_id),
		job_key_mode := 'preserve_run_at',
		max_attempts := 2,
		priority := 90
      )
	from
		nft
	where
		image is null
		and 
	address in
	(
		select
			address
		from
			nft_collection_stats ncs
		where
			address <> '0x495f947276749ce646f68ac8c248420045cb7b5e'
			and address <> '0x8c9b261faef3b3c2e64ab5e58e04615f8c788099'
			and default_image is not null
		order by
			transfers_total desc
		limit 10)) jobs
	