import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.4'

type CleanupLease = {
  company_id: string
  operation_id: string
  bucket_id: string
  storage_reference: string
}

function constantTimeMatch(actual: string, expected: string): boolean {
  const encoder = new TextEncoder()
  const left = encoder.encode(actual)
  const right = encoder.encode(expected)
  let difference = left.length ^ right.length
  const maxLength = Math.max(left.length, right.length)
  for (let index = 0; index < maxLength; index++) {
    difference |= (left[index] ?? 0) ^ (right[index] ?? 0)
  }
  return difference === 0
}

Deno.serve(async (request: Request) => {
  if (request.method !== 'POST') {
    return new Response(null, { status: 405 })
  }

  const secret = Deno.env.get('HORUS_DOCUMENT_CLEANUP_SECRET')
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const suppliedSecret = request.headers.get('authorization')?.replace(
    /^Bearer /i,
    '',
  ) ?? ''

  if (!secret || !supabaseUrl || !serviceRoleKey) {
    return new Response(null, { status: 503 })
  }
  if (!constantTimeMatch(suppliedSecret, secret)) {
    return new Response(null, { status: 401 })
  }

  const client = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

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
