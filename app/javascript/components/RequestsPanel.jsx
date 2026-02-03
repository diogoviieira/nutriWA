import React, { useState, useEffect } from "react";

function RequestCard({ request, onAccept, onReject, loading }) {
  const formattedDate = new Date(request.requested_at).toLocaleString();

  return (
    <article className="nutritionist-card">
      <div className="nutritionist-info">
        <h2 className="nutritionist-name">{request.guest_name}</h2>
        <p className="nutritionist-location">{request.guest_email}</p>
        <p style={{ marginTop: "0.5rem", fontWeight: 500 }}>{formattedDate}</p>
      </div>
      <div className="nutritionist-actions">
        <button
          type="button"
          className="btn btn-success"
          onClick={() => onAccept(request.id)}
          disabled={loading}
        >
          Accept
        </button>
        <button
          type="button"
          className="btn btn-danger"
          onClick={() => onReject(request.id)}
          disabled={loading}
        >
          Reject
        </button>
      </div>
    </article>
  );
}

export default function RequestsPanel({ nutritionistId, apiUrl }) {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [actionLoading, setActionLoading] = useState(false);

  const loadRequests = async () => {
    try {
      const response = await fetch(apiUrl);
      if (!response.ok) throw new Error("Failed to load");
      const data = await response.json();
      setRequests(data);
      setError(null);
    } catch (err) {
      setError("Error loading requests.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadRequests();
  }, []);

  const handleAction = async (id, action) => {
    setActionLoading(true);
    const url = `/api/nutritionists/${nutritionistId}/appointment_requests/${id}/${action}`;

    try {
      const response = await fetch(url, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
      });

      if (response.ok) {
        await loadRequests();
      } else {
        alert("Action failed. Please try again.");
      }
    } catch (err) {
      alert("Network error. Please try again.");
    } finally {
      setActionLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="empty-state">
        <p>Loading requests...</p>
      </div>
    );
  }

  if (error) {
    return <div className="flash flash-alert">{error}</div>;
  }

  if (requests.length === 0) {
    return (
      <div className="empty-state">
        <p>No pending requests.</p>
      </div>
    );
  }

  return (
    <div>
      {requests.map((request) => (
        <RequestCard
          key={request.id}
          request={request}
          onAccept={(id) => handleAction(id, "accept")}
          onReject={(id) => handleAction(id, "reject")}
          loading={actionLoading}
        />
      ))}
    </div>
  );
}
