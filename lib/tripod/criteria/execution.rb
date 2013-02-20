# This module defines behaviour for criteria
module Tripod

  # this module provides execution methods to a criteria object
  module CriteriaExecution

    extend ActiveSupport::Concern

    # Execute the query and return an array of all hydrated resources
    def resources
      resources_from_sparql(build_select_query)
    end

    # Execute the query and return the first result as a hydrated resource
    def first
      sq = Tripod::SparqlQuery.new(build_select_query)
      first_sparql = sq.as_first_query_str
      resources_from_sparql(first_sparql).first
    end

    # Return how many records the current criteria would return
    def count
      sq = Tripod::SparqlQuery.new(build_select_query)
      count_sparql = sq.as_count_query_str
      result = Tripod::SparqlClient::Query.select(count_sparql)
      result[0][".1"]["value"].to_i
    end

    # PRIVATE:

    included do

      private

      def resources_from_sparql(sparql)
        uris_and_graphs = self.resource_class._select_uris_and_graphs(sparql)
        self.resource_class._create_and_hydrate_resources(uris_and_graphs)
      end

      def build_select_query

        # convert the order, limit and offset to extras in the right order
        extras(order_clause)
        extras(limit_clause)
        extras(offset_clause)

        if graph_uri
          select_query = "SELECT ?uri (<#{graph_uri}> as ?graph) WHERE { GRAPH <#{graph_uri}> "
        else
          select_query = "SELECT ?uri ?graph WHERE { GRAPH ?graph "
        end

        select_query += "{ "
        select_query += self.where_clauses.join(" . ")
        select_query += " } } "
        select_query += self.extra_clauses.join(" ")
        select_query.strip
      end

    end

  end
end