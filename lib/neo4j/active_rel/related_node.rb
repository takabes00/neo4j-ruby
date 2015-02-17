module Neo4j::ActiveRel
  # A container for ActiveRel's :inbound and :outbound methods. It provides lazy loading of nodes.
  # It's important (or maybe not really IMPORTANT, but at least worth mentioning) that calling method_missing
  # will result in a query to load the node if the node is not already loaded.
  class RelatedNode
    class InvalidParameterError < StandardError; end

    # ActiveRel's related nodes can be initialized with nothing, an integer, or a fully wrapped node.
    #
    # Initialization with nothing happens when a new, non-persisted ActiveRel object is first initialized.
    #
    # Initialization with an integer happens when a relationship is loaded from the database. It loads using the ID
    # because that is provided by the Cypher response and does not require an extra query.
    #
    # Initialization with a node doesn't appear to happen in the code. TODO: maybe find out why this is an option.
    def initialize(node = nil)
      @node = valid_node_param?(node) ? node : (fail InvalidParameterError, 'RelatedNode must be initialized with either a node ID or node')
    end

    # Loads the node if needed, then conducts comparison.
    def ==(other)
      loaded if @node.is_a?(Integer)
      @node == other
    end

    # Returns the neo_id of a given node without loading.
    def neo_id
      loaded? ? @node.neo_id : @node
    end

    # Loads a node from the database or returns the node if already laoded
    def loaded
      @node = @node.respond_to?(:neo_id) ? @node : Neo4j::Node.load(@node)
    end

    # @return [Boolean] indicates whether a node has or has not been fully loaded from the database
    def loaded?
      @node.respond_to?(:neo_id)
    end

    def method_missing(*args, &block)
      loaded.send(*args, &block)
    end

    def class
      loaded.send(:class)
    end

    private

    def valid_node_param?(node)
      node.nil? || node.is_a?(Integer) || node.respond_to?(:neo_id)
    end
  end
end
