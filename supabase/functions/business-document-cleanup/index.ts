import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.4'

type CleanupLease = {
  company_id: string
  operation_id: string
  bucket_id: string
  storage_reference: string
}

Deno.serve(async (request: Request) => {
  if (request.method !== 'POST') {
    return new Response(null, { status: 405 })
  }

  // Platform JWT checking is disabled for this scheduled-service endpoint:
  // a separate 256-bit random token, generated and held only in Vault,
  // is verified by a service-role-only PostgreSQL RPC before any mutation.
  const suppliedToken = request.headers.get('authorization')?.match(
    /^Bearer ([0-9a-f]{64})$/,
  )?.[1]
  if (!suppliedToken) {
    return new Response(null, { status: 401 })
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!supabaseUrl || !serviceRoleKey) {
    return new Response(null, { status: 503 })
  }

  const client = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  // Never return the token or Vault contents in an HTTP response or logs.
  const { data: authorized, error: authorizationError } = await client.rpc(
    'authorize_business_document_cleanup',
    { p_supplied_token: suppliedToken },
  )
  if (authorizationError) {
    console.error('Document cleanup authorization unavailable', authorizationError.code)
    return new Response(null, { status: 503 })
  }
  if (authorized !== true) {
    return new Response(null, { status: 401 })
  }

  const { data, error } = await client.rpc('claim_business_document_cleanup', {
    p_batch_limit: 25,
  })
  if (error) {
    console.error('Document cleanup claim failed', error.code)
    return Response.json({ status: 'failed_to_claim' }, { status: 503 })
  }

  const leases = (data ?? []) as CleanupLease[]
  let cleaned = 0
  let deferred = 0

  for (const lease of leases) {
    if (
      !['business-documents', 'driver-documents'].includes(lease.bucket_id) ||
      !lease.storage_reference.startsWith('companies/' + lease.company_id + '/')
    ) {
      deferred++
      continue
    }

    // Service role is restricted to this backend runtime. Removal via the
    // Storage API deletes object bytes and database metadata together.
    const { error: removeError } = await client.storage
      .from(lease.bucket_id)
      .remove([lease.storage_reference])
    if (removeError) {
      deferred++
      console.warn('Document cleanup deletion deferred', removeError.name)
      continue
    }

    // Server-side function checks the object is gone and no metadata
    // references it before the durable reservation is marked cleaned.
    const { error: completeError } = await client.rpc(
      'complete_business_document_cleanup',
      {
        p_company_id: lease.company_id,
        p_operation_id: lease.operation_id,
      },
    )
    if (completeError) {
      deferred++
      console.warn('Document cleanup completion deferred', completeError.code)
    } else {
      cleaned++
    }
  }

  return Response.json({
    status: 'completed',
    inspected: leases.length,
    cleaned,
    deferred,
  })
})
